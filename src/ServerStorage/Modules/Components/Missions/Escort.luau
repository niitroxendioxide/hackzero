--[[
    World handler for the 'Escort' mission kind: get the escort out alive.

    The escort is a Recruit (see RecruitService) that follows the first player to load from
    the moment the mission begins. Losing it fails the run.

    Reads from `Builder:GetData()`, all optional: `Escorted` (its kind out of
    `Database/Recruits`) and `Escort_Overrides` (merged over its data).
]]

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const Shared = ReplicatedStorage.Modules.Shared
const Classes = ServerStorage.Modules.Classes
const Services = ServerStorage.Modules.Services

const GameEnum = require(Shared.GameEnum)
const StageTypes = require(Shared.Types.Stages)
const RecruitsDatabase = require(Shared.Database.Recruits)
const StageClass = require(Classes.Game.Stage)
const MissionBuilder = require(Classes.Game.MissionBuilder)
const PlayersLibrary = require(ServerStorage.Modules.Libraries.Players)
const AgentService = require(Services.Combat.AgentService)
const RecruitService = require(Services.Combat.RecruitService)

--- How far behind its owner's agent the escort starts.
const SPAWN_DISTANCE = 6

const GameStage = StageClass.new()

--- Who to escort, read off the packet at build time and spawned once the mission begins.
const Escort = {
    Name = 'Template',
    Overrides = nil :: {[string]: any}?,
}

GameStage:OnBuild(function(Builder: MissionBuilder.MissionBuilder)
    const Data = Builder:GetData()

    Escort.Name = Data.Escorted or 'Template'
    Escort.Overrides = Data.Escort_Overrides

    const EscortedPerson = (Escort.Overrides and Escort.Overrides.Display_Name) or RecruitsDatabase:GetData(Escort.Name).Display_Name
    --const Enemy = Data.Enemy or DEFAULT_ENEMY
    --const Level = (Data.Enemy_Level or DEFAULT_LEVEL) :: number
    --const FillerRooms = (Data.Filler_Rooms or DEFAULT_FILLER_ROOMS) :: number

    Builder:SetBeginEvent({
        Objective = `Help {EscortedPerson} leave this place.`,
        Goal = {},
        Enemies = {},
        Dialogue = {{
            Speaker = "Agency",
            Text = `I'll guide you to the correct path, just make sure {EscortedPerson} isn't hurt.`,
            NextDialogue = 2.75,
        }, {
            Speaker = "Agency",
            Text = "There's some agressive anima up ahead, so beware.",
            NextDialogue = 2.75,
        }},
        Global = true,
        Finished = 'None',
    })

    local RoomActualIndex = 0;
    local Rooms = Builder:PickRooms(120)

    for Index, Room in Rooms do
        const WAVES_GENERATED = math.floor(2 + Builder.__Random:NextNumber(0.15 * RoomActualIndex, 0.3 * RoomActualIndex) );

        const EnemyList = {};
        local TotalEnemies = 0;
        
        for i = 1, WAVES_GENERATED do
            local WaveCount = 3;
            EnemyList[i] = {}
            
            const ENEMIES_COUNT = 1;
            TotalEnemies += WaveCount;
            
            for i = 1, ENEMIES_COUNT do
                table.insert(EnemyList[i], {
                    Name = "Sorcerer",
                    Level = 10,
                    Amount = WaveCount,
                })
            end
        end

        Builder:AddEvent(Room, {
            Objective = "Clear the way {objective[KillEnemies]}",
            Goal = {
                ['KillEnemies'] = TotalEnemies,
            },
            Enemies = EnemyList,
            Tags = {'Filler'},

            Finished = 'None',
        })

        RoomActualIndex += 1;
    end
end)

GameStage:AddHook(GameEnum.StageHook.Begin, function(_Mission: StageTypes.MissionClass, _Payload)
    --- The first player to load leads the escort.
    local Owner = nil
    for _, StagePlayer in PlayersLibrary:GetAll() do
        if Owner == nil or StagePlayer:GetId() < Owner:GetId() then
            Owner = StagePlayer
        end
    end

    if Owner == nil then
        warn("[Escort] No player to hand the escort to.")

        return
    end

    const Agent = AgentService:GetCurrentCharacter(Owner:GetBase())
    if Agent == nil then
        warn("[Escort] The escort's owner has no agent to follow.")

        return
    end

    --- Losing the escort is losing the mission, whatever else the overrides say.
    const Overrides = table.clone(Escort.Overrides or {})
    Overrides.On_Defeat = table.clone(Overrides.On_Defeat or {})
    Overrides.On_Defeat.Fail_Mission = true

    RecruitService:Create(Escort.Name, Owner:GetBase(), Agent:GetPivot() * CFrame.new(0, 0, SPAWN_DISTANCE), Overrides)
end)

return GameStage
