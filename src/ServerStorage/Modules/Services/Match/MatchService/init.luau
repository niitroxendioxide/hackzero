--[[
    @class MatchService

    Owns the lifecycle of a single match server:
      teleport payload -> match context -> map (static or procedural) -> mission -> rewards

    Everything the run needs is resolved once into `Service.__Context` and read from there,
    rather than re-reading the teleport payload at every step.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Modules.Classes
local Services = Modules.Services
local Database = Shared.Database

local Places = require(ReplicatedStorage.Modules.Shared.Places)
local LootService = require(script.Parent.LootService)
local NPCService = require(script.Parent.NPCService)
local Stages = require(ReplicatedStorage.Modules.Shared.Types.Stages)
local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local World = require(ReplicatedStorage.Modules.Shared.World)
local Map = require(ServerStorage.Modules.Libraries.Map)

local Network = require(Shared.Network)
local Targets = require(ServerStorage.Modules.Libraries.Targets)
local AgentService = require(ServerStorage.Modules.Services.Combat.AgentService)
local CompanionService = require(ServerStorage.Modules.Services.Combat.CompanionService)
local DataService = require(ServerStorage.Modules.Services.Data.DataService)
local ChaosControlService = require(ServerStorage.Modules.Services.Lobby.ChaosControlService)
local Rewards = require(ServerStorage.Modules.Services.Match.MatchService.Rewards)
local settings = require(ServerStorage.Modules[".testenv"].settings)
local GameEnum = require(Shared.GameEnum)

local MissionClass = require(Classes.Game.Mission)
local MissionBuilder = require(Classes.Game.MissionBuilder)
local StageHandlers = require(Modules.Libraries.StageHandlers)
local StageDatabase = require(Database.Stages)
local MissionDatabase = require(Database.Missions)
local PlayersLibrary = require(Modules.Libraries.Players)
local AbilityService = require(Services.Combat.AbilityService)
local TeleportService = require(Services.Data.TeleportService);
local DestructibleService = require(Services.Match.DestructibleService)

--
local RANK_ORDER = {"B", "A", "S"}
local MAX_SEED = 2 ^ 31 - 1

--[[
    Everything a single run is built from, resolved once in `ResolveContext`.
]]
export type MatchContext = {
    Type: Stages.MissionType,
    Stage: string,
    Act: string,
    Difficulty: string,

    --- Set only for a mission that exists in the database. A runtime-authored one has none.
    Mission_Id: string?,

    --[[
        What kind of mission this is, e.g. 'Recover'. This is what picks the world handler,
        and it is the only classification a runtime-authored mission needs.
    ]]
    Kind: string?,
    --- The component running this mission, by kind first and stage act second.
    --- Resolved lazily by `GetHandler`, `false` once resolved to nothing.
    Handler: any?,
    --- Whether the world handler authored this mission rather than it coming pre-written.
    Built: boolean,

    --- Seed the map was built from, always a concrete number once the map exists.
    Seed: number,
    Procedural: boolean,

    --- Resolved generation parameters, only present on a procedural run.
    Generation: Stages.MapGenerationData?,
    --- What the generator actually built, only present once the map exists.
    Generated: Stages.MapGenerationResult?,

    --- The mission block's raw `Data` from the teleport payload, kept so nothing has to
    --- go back to `TeleportService` once the context exists.
    Payload: {[string]: any},

    --- World data the mission runs on: Guide / Destructibles / Completion.
    Data: {[string]: any},
    --- Markers to lay out, mission-declared entries merged with generated rooms.
    Markers: {[string]: Stages.Marker},
    Dialogues: { [string]: { any }? },

    Total_Players: number,
}

local Service = {
    __Context = nil :: MatchContext?,
    __Active_Match = nil,
    __Total_Players = 0,
    __Player_Status = {},
}

--[[
    Turn a seed of any shape into the integer the generator wants.
    Mission seeds are authored as readable strings (`'12345-abcde-67890-fabcd'`), so those
    get folded down to a number instead of being dropped.
]]
local function ToSeedNumber(Value: (string | number)?): number
    if typeof(Value) == 'number' then
        return math.floor(math.abs(Value)) % MAX_SEED
    end

    if typeof(Value) ~= 'string' or #Value < 1 then
        return 0
    end

    local Hash = 2166136261 % MAX_SEED
    for Index = 1, #Value do
        Hash = (Hash * 31 + string.byte(Value, Index)) % MAX_SEED
    end

    return Hash
end

local function FirstDefined(...: any): any
    for Index = 1, select('#', ...) do
        local Value = select(Index, ...)

        if Value ~= nil then
            return Value
        end
    end

    return nil
end

--[[
    Merge generation parameter layers, later layers overriding earlier ones.
    Order is: stage act defaults -> mission database entry -> whatever the run was
    started with, so an NPC-generated mission can override the stage's defaults.
]]
local function MergeGeneration(...: {[string]: any}?): {[string]: any}
    local Merged = {}

    for Index = 1, select('#', ...) do
        local Layer = select(Index, ...)

        if typeof(Layer) == 'table' then
            for Key, Value in Layer do
                Merged[Key] = Value
            end
        end
    end

    return Merged
end

function Service:Init()
    Network.new("Match", "Event")

    if not Places:CanFight() then
        return;
    end

    Network:On("Match", Service.__HandleEvent)

    local MatchData = TeleportService:GetStageData()
    local Context = Service:ResolveContext(MatchData)

    if not Service:CreateMap(Context) then
        Debugger:WarnLine("MatchService::Init", "Map could not be built for " .. Context.Stage .. "/" .. tostring(Context.Act), 1)

        TeleportService:ReturnToLobby(Players:GetPlayers())

        return;
    end

    Service.__Total_Players = Context.Total_Players

    local LoadedPlayers = 0
    while LoadedPlayers < Context.Total_Players do
        if (RunService:IsRunMode()) then
            break
        end

        LoadedPlayers = 0

        for _, Player in Players:GetPlayers() do
            if Player:HasTag("Loaded") then
                LoadedPlayers += 1;
            end
        end

        task.wait()
    end

    for _, Player in Players:GetPlayers() do
        Service:SetPlayerLifeStatus(Player, true)

        Network:Fire("Match", Player, GameEnum.MatchEvents.SetupStage, Context.Stage, Context.Act)
    end

    Service:Begin()
end

--[[
    Fold the teleport payload, the mission database entry and the stage act into one
    context. Nothing downstream reads the raw payload after this.

    @param MatchData The payload `TeleportService:GetStageData` produced.
]]
function Service:ResolveContext(MatchData: TeleportService.MatchData): MatchContext
    local MissionData = MatchData.Mission
    local MissionPayload = MissionData.Data or {}
    local MissionId = MissionPayload.MissionId

    local MissionInfo = MissionId and MissionDatabase:Get(MissionId)
    local ActInfo = StageDatabase:GetAct(MissionData.Stage, MissionData.Act)
    local Stage = MissionData.Stage;
    local Act = MissionData.Act;

    if MissionInfo and typeof(MissionInfo.Stage_Act) == 'string' then
        local Split_SDA = string.split(MissionInfo.Stage_Act, "/");
        Stage = Split_SDA[1];
        Act = Split_SDA[2];
    end

    local Context: MatchContext = {
        Type = (MissionData.Type or 'Mission') :: Stages.MissionType,
        Stage = Stage,
        Act = Act,
        Difficulty = MissionData.Difficulty or (MissionInfo and MissionInfo.Difficulty) or GameEnum.Difficulties.Easy,
        Mission_Id = MissionId,

        Seed = 0,
        Procedural = false,
        Generation = nil,
        Generated = nil,

        Kind = MissionData.Kind or MissionPayload.Kind or (MissionInfo and MissionInfo.Kind),
        Handler = nil,
        Built = false,

        Payload = MissionPayload,
        Data = {},
        Markers = {},

        Total_Players = MatchData.TotalPlayers or 1,
    }

    Context.Procedural = FirstDefined(
        MissionData.Procedural,
        MissionPayload.Procedural,
        MissionInfo and MissionInfo.Procedural,
        ActInfo and ActInfo.AutoGenerate
    ) == true

    if Context.Procedural and not (ActInfo and ActInfo.AutoGenerate) then
        Debugger:DebugLine("MatchService::ResolveContext", "Procedural run on an act that doesn't declare AutoGenerate: " .. tostring(MissionData.Stage) .. "/" .. tostring(MissionData.Act), 1)
    end

    --- Seed: explicit number first, then the authored mission seed, else rolled later.
    Context.Seed = ToSeedNumber(FirstDefined(
        (MissionData.Seed ~= nil and MissionData.Seed ~= 0) and MissionData.Seed or nil,
        MissionPayload.Mission_Seed,
        MissionInfo and MissionInfo.Seed
    ))

    if Context.Procedural then
        Context.Generation = MergeGeneration(
            ActInfo and ActInfo.AutoGenerationData,
            MissionInfo and MissionInfo.Generation,
            MissionPayload.Generation,
            MissionData.Generation
        ) :: Stages.MapGenerationData

        Context.Generation.Seed = Context.Seed
    end

    Service.__Context = Context

    return Context
end

--[[
    The component that runs this mission: its kind's handler when there is one, otherwise
    the stage act's. A runtime-authored mission hooks into its kind's handler and never
    needs an act of its own.

    Resolved on first use rather than up front, since the component index builds in parallel
    with this service and may not be filled when the context is first assembled.
]]
function Service:GetHandler(Context: MatchContext): any?
    if Context.Handler ~= nil then
        return Context.Handler
    end

    Context.Handler = StageHandlers:Resolve(Context.Kind, Context.Stage, Context.Act) or false

    if Context.Kind and not StageHandlers:GetMission(Context.Kind) then
        Debugger:WarnLine(
            "MatchService::GetHandler",
            "No world handler for mission kind '" .. tostring(Context.Kind) .. "', add one at Components/Missions/" .. tostring(Context.Kind),
            1
        )
    end

    return Context.Handler or nil
end

--[[
    Build the world for this run.

    Procedural runs go through the dungeon generator and report back the seed they were
    actually built with (relevant when the seed was rolled here), static runs unpack the
    stage's map asset.

    @return Whether the map is standing.
]]
function Service:CreateMap(Context: MatchContext): boolean
    local StageInformation = StageDatabase:GetStage(Context.Stage)

    if not StageInformation then
        Debugger:WarnLine("MatchService::CreateMap", "Unknown stage: " .. tostring(Context.Stage), 1)

        return false
    end

    if not Context.Procedural then
        return Map:Unpack(StageInformation.Map)
    end

    local Generated = Map:Generate(StageInformation.Map, Context.Generation)
    if not Generated then
        return false
    end

    Context.Generated = Generated
    Context.Seed = Generated.Seed

    Debugger:DebugLine(
        "MatchService::CreateMap",
        string.format("Generated %d rooms (%d halls) with seed %d", Generated.RoomCount, Generated.HallCount, Generated.Seed),
        1
    )

    return true
end

--[[
    Where a Mission's definition comes from, in order:

    1. `Data.Mission` on the packet - a mission authored at runtime, in full, by whoever
       built the packet. Never touches the database.
    2. `Data.MissionId` - a pre-generated mission out of the database.
    3. Nothing - a mission that is purely its kind, and expects its world handler to author
       everything from the seed and the rooms.

    Only (2) requires the mission to exist anywhere ahead of time.
]]
local function GetMissionDefinition(Context: MatchContext): {[string]: any}?
    local Inline = Context.Payload.Mission

    if typeof(Inline) == 'table' then
        return Inline
    end

    if Context.Mission_Id then
        return MissionDatabase:Get(Context.Mission_Id)
    end

    return nil
end

--[[
    Hand the run to its world handler so it can author the mission into the map that was
    just generated.

    Runs after the map exists and before markers are laid out, which is the only window
    where a handler can still decide where things go.

    @return The definition with whatever the handler built merged in.
]]
function Service:RunBuildPass(Context: MatchContext, Definition: {[string]: any}?): {[string]: any}?
    local Handler = Service:GetHandler(Context)
    if not Handler or not Handler:HasBuilder() then        
        return Definition
    end

    local Builder = MissionBuilder.new({
        Seed = Context.Seed,
        Kind = Context.Kind,
        Data = Context.Payload,
        Rooms = Context.Generated and Context.Generated.Rooms or {},
    })

    local Ran, Message = Handler:ExecuteBuild(Builder)
    if not Ran then
        Debugger:WarnLine("MatchService::RunBuildPass", "World handler for '" .. tostring(Context.Kind) .. "' errored: " .. tostring(Message), 1)

        return Definition
    end

    if Builder:IsEmpty() then
        Debugger:WarnLine("MatchService::RunBuildPass", "World handler for '" .. tostring(Context.Kind) .. "' placed nothing", 1)
    end

    local Built = Builder:Result()
    local Merged = table.clone(Definition or {})

    for Key, Value in Built do
        if Value == nil or (typeof(Value) == 'table' and next(Value) == nil) then
            continue
        end

        Merged[Key] = Value
    end

    Context.Built = true

    return Merged
end

--[[
    Resolve the world data the mission object runs on, and the markers to lay out.

    - Mission      -> the packet's own definition, or the database entry, or nothing at all,
                      then whatever the world handler authors on top
    - ChaosControl -> the payload the lobby handed over
    - Expedition   -> the stage act itself

    Rooms the generator placed are merged into the marker set afterwards, so a generated
    dungeon walks the same trigger path a hand-built map does.
]]
function Service:ResolveWorldData(Context: MatchContext): boolean
    local ActData = StageDatabase:GetAct(Context.Stage, Context.Act)
    local MissionPayload = Context.Payload

    if Context.Type == 'Mission' then
        local Definition = Service:RunBuildPass(Context, GetMissionDefinition(Context))
        if not Definition then
            Debugger:WarnLine(
                "MatchService::ResolveWorldData",
                "No mission definition. Packet carried neither Data.Mission nor Data.MissionId, and kind '" .. tostring(Context.Kind) .. "' has no world handler that built one.",
                1
            )

            return false
        end

        Context.Data = {
            Guide = Definition.Triggers,
            Destructibles = Definition.Destructibles,
            Completion = Definition.Completion,
            Dialogues = Definition.Dialogues,
        }

        Context.Markers = Definition.Markers or (ActData and ActData.Markers) or {}
    elseif Context.Type == 'ChaosControl' then
        Context.Data = MissionPayload
        Context.Markers = MissionPayload.Markers or {}
    elseif Context.Type == 'Expedition' then
        if not ActData then
            Debugger:WarnLine("MatchService::ResolveWorldData", "Unknown act " .. tostring(Context.Stage) .. "/" .. tostring(Context.Act), 1)

            return false
        end

        Context.Data = ActData
        Context.Markers = ActData.Markers or {}
    else
        Debugger:WarnLine("MatchService::ResolveWorldData", "Unknown mission type: " .. tostring(Context.Type), 1)

        return false
    end

    Context.Markers = Map:CreateMarkersForGeneratedMap(Context.Markers)

    return true
end

--[[
    Reward payload for the end screen, tolerant of acts that never declared a Completion
    block (procedural ones generally have not).
]]
local function GetCompletion(Context: MatchContext): {Experience: number, Rewards: {[string]: {any}}}
    local Completion = Context.Data.Completion or {}

    return {
        Experience = Completion.Experience or 0,
        Rewards = Completion.Rewards or {},
    }
end

function Service:End(Won: boolean)
    if not Service.__Active_Match or not Service.__Active_Match:IsFinished() then
        return
    end

    local Context = Service.__Context
    if not Context then
        return
    end

    Debugger:DebugLine("MatchService::End", "Ending mission", 1)

    ---
    World:SetEndScreenMode(true)
    World:TweenSpeed(0.01, 2)

    --- Calculate and Spread completion info
    local Completion = GetCompletion(Context)
    local Rank = Service.__Active_Match:ObtainMissionRank(Won);
    local RawRewards = Completion.Rewards
    local CompletionRewards = {}
    local RankTier = table.find(RANK_ORDER, Rank)

    --- A rank outside the reward ladder (a loss ranks 'X') simply earns nothing.
    for Tier, LetterRank in RANK_ORDER do
        if RankTier == nil or Tier > RankTier or RawRewards[LetterRank] == nil then
            continue
        end

        for _, Object in RawRewards[LetterRank] do
            if ((Object.Type == 'Money' or Object.Type == 'Gold') or Object.Type == 'Gems') then
                local Edited = false
                for _, Item in CompletionRewards do
                    if Item.Type ~= Object.Type then continue end

                    Edited = true
                    Item.Amount += Object.Amount;
                end

                if Edited then
                    continue
                end
            end

            table.insert(CompletionRewards, {Type = Object.Type, Amount = Object.Amount, Extra = Object.Extra})
        end
    end

    local MatchCompletionData = {
        Stage = {
            Type = Context.Type,
            Stage = Context.Stage,
            Act = Context.Act,
            --- The seed the map was actually built with, so a run can be replayed.
            Seed = Context.Seed,
            Procedural = Context.Procedural,
            Difficulty = Context.Difficulty,
        },
        WinStatus = Won and GameEnum.MatchResults.Victory or GameEnum.MatchResults.Loss,
        TotalDamage = AbilityService.__Total_Damage,
        Rank = Rank;
        Experience = Completion.Experience,
    };

    for _, Player in Players:GetPlayers() do
        ChaosControlService:MarkCompletion(Player, MatchCompletionData)
    end

    Service.__Active_Match = nil

    Rewards:SpreadRewards(PlayersLibrary:GetAll(), CompletionRewards, MatchCompletionData)
end

function Service:Begin()
    local Context = Service.__Context
    if not Context then
        Debugger:WarnLine("MatchService::Begin", "No resolved match context", 1)

        return
    end

    if Service.__Active_Match then
        return
    end

    if not Service:ResolveWorldData(Context) then
        TeleportService:ReturnToLobby(Players:GetPlayers())

        return
    end

    Debugger:DebugLine("MatchService::Begin", "Starting Mission", 1)

    local Difficulty = RunService:IsStudio() and settings.DIFFICULTY or Context.Difficulty
    if Context.Stage == 'Training' and not RunService:IsStudio() then
        Difficulty = GameEnum.Difficulties.Easy
    end

    Targets:SetDifficulty(Difficulty)

    --
    local AllPlayers = Players:GetPlayers()
    if #AllPlayers == 0 then
        Debugger:WarnLine("MatchService::Begin", "Match is debug.", 1)

        return
    end

    if Context.Mission_Id then
        Network:FireForAll("Match", GameEnum.MatchEvents.SetMissionId, Context.Mission_Id)
    end

    if Context.Data and Context.Data.Dialogues then
        Network:FireForAll("Match", GameEnum.MatchEvents.AllocateDialogueData, Context.Data.Dialogues);
    end

    local Marker_Data = Map:SetupMarkers(Context.Markers)
    local MissionObject = MissionClass.new({
        Type = Context.Type,
        Stage = Context.Stage,
        Act = Context.Act,
        Data = Context.Data,
        Seed = Context.Seed,
        Procedural = Context.Procedural,
        Generated_Rooms = Context.Generated and Context.Generated.Rooms or {},
        Hooks = Service:GetHandler(Context),
    })

    Map:AssignCurrentMission(MissionObject)

    NPCService.__Stage = Context.Stage
    NPCService.__Act = Context.Act
    NPCService:SetMarkers(Context.Markers)

    DestructibleService:SetupStage(Marker_Data.Destructibles, Context.Data.Destructibles or {})
    LootService:SetupChests(Marker_Data.Chests)
    NPCService:SetupNPCS(Marker_Data.NPCS)

    Service.__Active_Match = MissionObject;

    Network:FireForAll("Match", GameEnum.MatchEvents.MatchBegin, Service:GetClientPayload(Context))

    --
    for _, Player in AllPlayers do
        local FirstAgent = AgentService:GetCurrentCharacter(Player)
        local CompData = DataService:GetCompanions(Player, function(Companion): boolean
            return true
        end, true)

        if CompData ~= nil then
            CompanionService:CreateCompanion(CompData, FirstAgent)
        end
    end

    --
    DestructibleService.StructureSetValuesEvent:Connect(function(Values: {[string]: any})
        for Key, Value in Values do
            local IsAddition = typeof(Value) == 'number' and (string.sub(Key, #Key, #Key) == "+")
            local CorrectedKey = IsAddition and string.sub(Key, 1, #Key - 1) or Key
            local CorrectedValue = IsAddition and (MissionObject:GetProgressValue(CorrectedKey) or 0) + Value or Value

            MissionObject:SetProgressValue(CorrectedKey, CorrectedValue)
        end
    end)

    MissionObject.Finished:Once(function(Won: boolean)
        Service:End(Won)
    end)

    if LootService.OnLootboxOpened then
        LootService.OnLootboxOpened:Connect(function(Player, Loot)
            local StagePlayerObject = PlayersLibrary:Get(Player) :: Stages.StagePlayer

            for ItemName, ItemData in Loot.Items do
                StagePlayerObject:AddLoot(ItemName, ItemData)
            end
        end)
    end

    --[[
        Started last, on purpose. `Begin` runs the first event synchronously and a goalless
        one can finish the mission on the spot, which would fire `Finished` before anything
        above had subscribed to it.
    ]]
    MissionObject:Begin()
end

--- What the client needs at match start, on top of what SetupStage already sent.
function Service:GetClientPayload(Context: MatchContext): {[string]: any}
    local Payload = {
        Seed = Context.Seed,
        Procedural = Context.Procedural,
    }

    if Context.Type == 'ChaosControl' then
        local WaveCount = 0;
        for _, _ in (Context.Data.Enemies or {}) do
            WaveCount += 1;
        end

        Payload.TotalWaves = WaveCount
    end

    return Payload
end

function Service:SetPlayerLifeStatus(Player: Player, State: boolean)
    Service.__Player_Status[Player] = State

    if State == false then
        local AllDead = true
        for _, OtherPlayerState in Service.__Player_Status do
            if OtherPlayerState == true then
                AllDead = false
            end
        end

        if not AllDead then return end

        Service:Lose()
    end
end

function Service:Lose()
    if not Service.__Active_Match then
        return
    end

    Service.__Active_Match:Finish(false)
end

--- Context this server is running, nil outside a match.
function Service:GetContext(): MatchContext?
    return Service.__Context
end

--- Seed the map was built with, 0 for a static map.
function Service:GetSeed(): number
    return Service.__Context and Service.__Context.Seed or 0
end

-- ## Private event
function Service.__HandleEvent(Player: Player, Type: number)
    if Type == GameEnum.MatchEvents.RequestMatchLeave then
        local Result, Message = TeleportService:ReturnToLobby(Players:GetPlayers())
        if not Result then
            warn(Message)
        end
    elseif Type == GameEnum.MatchEvents.SingularPlayerLeave then
        local Result, Message = TeleportService:ReturnToLobby({Player})
        if not Result then
            warn(Message)
        end
    elseif Type == GameEnum.MatchEvents.RequestMatchRepeat then
        local Result, Message = TeleportService:RepeatStage()
        if not Result then
            warn(Message)
        end
    elseif Type == GameEnum.MatchEvents.MarkClientLoaded then
        Player:AddTag("MapLoaded")
    elseif Type == GameEnum.MatchEvents.PlayerDied then
        Service:SetPlayerLifeStatus(Player, false)
    end
end

return Service
