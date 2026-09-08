--[[
    @class Generator
    Builds a dungeon layout by walking outwards from a starting room, alternating
    room -> hall -> room. The layout is fully determined by the seed it is given, so the
    same seed always rebuilds the same dungeon.
]]

--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


--- Constants
local SIZE_CONSTANT = 1 / 1.1
local VIEW_TIME = 0.01
local TILE_SIZE = 96
local BASE_CFRAME = CFrame.new(0, 0, 0)
local TILE_OFFSET = CFrame.new(0, 0, -(TILE_SIZE / 2)) * CFrame.Angles(0, math.pi, 0)
local TILE_AREA_SIZE = vector.create(TILE_SIZE, TILE_SIZE, TILE_SIZE)

local DEFAULT_ROOM_COUNT = 25
local MAX_SEED = 2 ^ 31 - 1

local HALL_TAG = 'Hall'

--[[
    Tag for the piece used to plug a doorway that leads nowhere. Optional: without one, any
    closed room is used instead. Tag a small filler room with this and it becomes the
    dedicated plug for those spots.
]]
local SEAL_TAG = 'Seal'


--- Generator Related
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)
local Result = require(Shared.Utility.Result)

local Generator = {};

export type GeneratorState = {
    Rng: Random,
    Seed: number,
    Rooms: {Types.GeneratedRoom},
    PlacedRooms: number,
    PlacedHalls: number,
    PlacedTiles: number,
    RoomLimit: number,
    TileLimit: number,
    Infinite: boolean,
    Trail: number,
    Source: Folder?,
    Warned_No_Closed_Room: boolean,

    --[[
        Doorways that were opened but never built through, collected during generation and
        plugged once it finishes. A connector is destroyed the moment it is walked, so
        without this the layout has no record of where its holes are.
    ]]
    Open_Connectors: {CFrame},
    PlacedSeals: number,
}

--- Every run gets a fresh state, nothing leaks between generations.
local function NewState(): GeneratorState
    return {
        Rng = Random.new(),
        Seed = 0,
        Rooms = {},
        PlacedRooms = 0,
        PlacedHalls = 0,
        PlacedTiles = 0,
        RoomLimit = DEFAULT_ROOM_COUNT,
        TileLimit = DEFAULT_ROOM_COUNT * 2,
        Infinite = false,
        Trail = 0,
        Source = nil,
        Warned_No_Closed_Room = false,
        Open_Connectors = {},
        PlacedSeals = 0,
    }
end

local State: GeneratorState = NewState()

--- Privates
local function GetMapFolder(): Folder
    local DesignFolder = workspace.World.Map:FindFirstChild('Design')
    if not DesignFolder then
        DesignFolder = Instance.new('Folder')
        DesignFolder.Name = 'Design'
        DesignFolder.Parent = workspace.World.Map
    end

    return DesignFolder
end

local function GetMarkerFolder(): Folder
    local MarkerFolder = workspace.World.Map:FindFirstChild("Markers")
    if not MarkerFolder then
        MarkerFolder = Instance.new("Folder")
        MarkerFolder.Name = 'Markers'
        MarkerFolder.Parent = workspace.World.Map
    end

    return MarkerFolder
end

--- Whether a tile slot is clear, used both when growing and when plugging holes.
local function IsSlotFree(At: CFrame): boolean
    local BoundParams = OverlapParams.new()
    BoundParams.FilterDescendantsInstances = {GetMapFolder()}
    BoundParams.FilterType = Enum.RaycastFilterType.Include

    local PartsInBox = workspace:GetPartBoundsInBox(At, vector.create(TILE_SIZE/2, TILE_SIZE/2, TILE_SIZE/2), BoundParams)

    return #PartsInBox < 1
end

local function GetStartingRoom(): Model?
    return State.Source and State.Source:FindFirstChild('StartingRoom') :: Model?
end

--[[
    How a pick treats closed pieces, meaning ones whose `Connections` folder is empty and so
    have nowhere to lead but back the way you came.

    Forbid  - never, the layout would stop growing
    Allow   - either is fine
    Require - only a closed piece, used to cap the dungeon off
]]
export type DeadEndRule = "Forbid" | "Allow" | "Require"

--[[
    Pick the next piece to place.

    @param IsStarting Return the mandatory starting room instead of rolling one.
    @param Hall Whether a hall or a room is wanted.
    @param DeadEnds How to treat closed pieces, defaults to Forbid.
]]
local function ChooseFromSource(IsStarting: boolean, Hall: boolean, DeadEnds: DeadEndRule?): Model?
    local RoomSource = State.Source;
    if not RoomSource then
        return nil;
    end

    local StartingRoom = GetStartingRoom()
    if IsStarting then
        return StartingRoom
    end

    local Rooms = RoomSource:GetChildren();

    local StartingIndex = StartingRoom and table.find(Rooms, StartingRoom)
    if StartingIndex then
        table.remove(Rooms, StartingIndex)
    end

    for k = #Rooms, 1, -1 do
        local Candidate = Rooms[k]
        local Connections = Candidate:FindFirstChild('Connections')

        if not Candidate:IsA('Model') or not Connections then
            table.remove(Rooms, k)
            continue
        end

        if Candidate:HasTag(HALL_TAG) ~= Hall then
            table.remove(Rooms, k)
            continue
        end

        local IsClosed = #Connections:GetChildren() < 1
        local Rule = DeadEnds or 'Forbid'

        if (Rule == 'Forbid' and IsClosed) or (Rule == 'Require' and not IsClosed) then
            table.remove(Rooms, k)
        end
    end

    if #Rooms < 1 then
        return nil
    end

    return Rooms[State.Rng:NextInteger(1, #Rooms)]
end

--- Rooms get an area marker so the mission layer can turn them into triggers.
local function CreateTriggerPart(BaseRoom: Model, Id: number): BasePart
    local Base = BaseRoom.PrimaryPart;
    local NewMarker = Instance.new("Part")
    NewMarker.Size = vector.create(TILE_SIZE / SIZE_CONSTANT, TILE_SIZE, TILE_SIZE) * SIZE_CONSTANT
    NewMarker.CFrame = Base.CFrame
    NewMarker.CastShadow = false
    NewMarker.Anchored = true
    NewMarker.CanCollide = false
    NewMarker.CanQuery = false
    NewMarker.Transparency = 1
    NewMarker.Color = Color3.new(1)
    NewMarker.Name = 'Room_' .. tostring(Id)
    NewMarker.Parent = GetMarkerFolder()
    NewMarker:SetAttribute("AreaSize", TILE_AREA_SIZE)

    return NewMarker
end

--[[
    Whether another piece still fits in the budget.
    Halls only exist to connect rooms, so once the room budget is spent they stop too,
    otherwise the layout ends in corridors leading nowhere.
]]
local function HasBudgetFor(): boolean
    if State.PlacedTiles >= State.TileLimit then
        return false
    end

    return State.PlacedRooms < State.RoomLimit
end

local function CreateRoom(RoomCFrame: CFrame?, UseHall: boolean)
    local IsStarting = State.PlacedTiles <= 0
    local MapFolder = GetMapFolder()

    if not IsStarting and not HasBudgetFor() then
        return;
    end

    --[[
        The room that spends the last of the budget caps the dungeon off, so it has to be a
        closed one: no outgoing connections, nothing but the doorway it was entered by.
        Every other room forbids closed pieces, or the layout would stop growing early.
    ]]
    local IsFinalRoom = not UseHall and (State.PlacedRooms + 1) >= State.RoomLimit
    local BaseRoom = ChooseFromSource(IsStarting, UseHall, if IsFinalRoom then 'Require' else 'Forbid');

    if not BaseRoom and IsFinalRoom then
        --[[
            The source has no closed room to cap with. Better to end on an open one than to
            leave the layout a room short, but say so, because the prefab folder is missing
            a piece it is expected to have.
        ]]
        if not State.Warned_No_Closed_Room then
            State.Warned_No_Closed_Room = true

            warn("Generator: no closed room (a model with an empty Connections folder) in " ..
                State.Source:GetFullName() .. ", the last room will be left open")
        end

        BaseRoom = ChooseFromSource(IsStarting, UseHall, 'Allow')
    end

    if not BaseRoom then
        return;
    end

    if RunService:IsStudio() then
        task.wait(VIEW_TIME)
    end

    if IsStarting then
        local FirstAngle = State.Rng:NextInteger(0, 3) * (math.pi / 2)
        local Clone = BaseRoom:Clone();
        Clone.PrimaryPart.Transparency = 1;
        Clone.Name = 'Room_0'
        Clone:PivotTo(BASE_CFRAME * CFrame.Angles(0, FirstAngle, 0))
        Clone.Parent = MapFolder

        workspace:FindFirstChild('SpawnLocation').CFrame = Clone:GetPivot()

        State.PlacedTiles = 1;
        State.PlacedRooms = 1;

        table.insert(State.Rooms, {
            Id = 0,
            Name = Clone.Name,
            Model = Clone,
            Marker = CreateTriggerPart(Clone, 0),
            IsHall = false,
        })

        local Connectors = Clone.Connections:GetChildren()
        local FirstConnector = Connectors[1]
        if not FirstConnector then
            return;
        end

        --[[
            The spawn room only ever grows out of its first doorway. The others were left
            standing open, so they go on the list to be plugged at the end.
        ]]
        for Index = 2, #Connectors do
            table.insert(State.Open_Connectors, Connectors[Index].CFrame * TILE_OFFSET)
            Connectors[Index]:Destroy()
        end

        local FirstCFrame = FirstConnector.CFrame;
        FirstConnector:Destroy()

        local Target = FirstCFrame * TILE_OFFSET
        local TilesBefore = State.PlacedTiles

        CreateRoom(Target, true);

        if State.PlacedTiles == TilesBefore then
            table.insert(State.Open_Connectors, Target)
        end

        return;
    end

    if not IsSlotFree(RoomCFrame) then
        return;
    end

    ---
    local Clone = BaseRoom:Clone();
    Clone.PrimaryPart.Transparency = 1;
    Clone:PivotTo(RoomCFrame);

    local SelfId;
    if UseHall then
        State.PlacedHalls += 1
        SelfId = State.PlacedHalls
        Clone.Name = 'Hall_' .. SelfId
    else
        SelfId = State.PlacedRooms
        Clone.Name = 'Room_' .. SelfId
    end

    Clone.Parent = MapFolder;

    State.PlacedTiles += 1;
    if not UseHall then
        State.PlacedRooms += 1;
    end

    table.insert(State.Rooms, {
        Id = SelfId,
        Name = Clone.Name,
        Model = Clone,
        Marker = if UseHall then nil else CreateTriggerPart(Clone, SelfId),
        IsHall = UseHall,
    })

    --
    for _, Connection in Clone.Connections:GetChildren() do
        local ConnectorCFrame = Connection.CFrame
        Connection:Destroy();

        local Target = ConnectorCFrame * TILE_OFFSET
        local TilesBefore = State.PlacedTiles

        CreateRoom(Target, not UseHall)

        --[[
            Nothing was placed there: out of budget, no candidate, or the slot was taken.
            Either way the doorway now opens onto nothing, so remember it. The plug pass
            re-checks the slot, which is what filters out the "already occupied" case.
        ]]
        if State.PlacedTiles == TilesBefore then
            table.insert(State.Open_Connectors, Target)
        end
    end
end

--[[
    Pick the piece used to plug a doorway that leads nowhere.

    Prefers anything tagged `Seal` — that is the slot for a small filler room built for
    these spots — and otherwise falls back to any closed room.
]]
local function ChooseSealPiece(): Model?
    local Source = State.Source
    if not Source then
        return nil
    end

    local StartingRoom = GetStartingRoom()
    local Tagged, Closed = {}, {}

    for _, Candidate in Source:GetChildren() do
        if not Candidate:IsA('Model') or Candidate == StartingRoom then
            continue
        end

        if Candidate:HasTag(SEAL_TAG) then
            table.insert(Tagged, Candidate)
            continue
        end

        if Candidate:HasTag(HALL_TAG) then
            continue
        end

        local Connections = Candidate:FindFirstChild('Connections')
        if Connections and #Connections:GetChildren() < 1 then
            table.insert(Closed, Candidate)
        end
    end

    local Pool = if #Tagged > 0 then Tagged else Closed
    if #Pool < 1 then
        return nil
    end

    return Pool[State.Rng:NextInteger(1, #Pool)]
end

--[[
    Plug every doorway that was left opening onto nothing.

    Runs after the layout is finished and deliberately ignores the room and tile budgets:
    these are not part of the dungeon's size, they are what stops it having holes in it.
    A slot another branch filled in the meantime is skipped, that doorway leads somewhere.
]]
local function SealOpenConnectors()
    if #State.Open_Connectors < 1 then
        return
    end

    local MapFolder = GetMapFolder()

    for _, At in State.Open_Connectors do
        if not IsSlotFree(At) then
            continue
        end

        local Piece = ChooseSealPiece()
        if not Piece then
            warn("Generator: nothing to plug open doorways with in " .. State.Source:GetFullName() ..
                ", tag a small room '" .. SEAL_TAG .. "' or add a closed room. " ..
                #State.Open_Connectors .. " doorway(s) left open")

            return
        end

        if RunService:IsStudio() then
            task.wait(VIEW_TIME)
        end

        State.PlacedSeals += 1

        local Clone = Piece:Clone()
        Clone.PrimaryPart.Transparency = 1
        Clone.Name = 'Seal_' .. State.PlacedSeals
        Clone:PivotTo(At)
        Clone.Parent = MapFolder

        --- A plug ends there, whatever the prefab carried must not grow the layout further.
        local Connections = Clone:FindFirstChild('Connections')
        if Connections then
            Connections:ClearAllChildren()
        end

        --[[
            No area marker on purpose. A plug is geometry, not somewhere a mission should
            put an objective, and everything downstream already skips rooms without one.
        ]]
        table.insert(State.Rooms, {
            Id = State.PlacedSeals,
            Name = Clone.Name,
            Model = Clone,
            Marker = nil,
            IsHall = false,
            IsSeal = true,
        })
    end
end

--- Public

--[[
    Build a layout out of `p_RoomSource`.

    @param p_RoomSource Folder holding a `StartingRoom` plus the room/hall models.
    @param p_GenerationData Resolved generation parameters. A `Seed` of 0 or lower means
           "roll one", the rolled value comes back in the result.

    @return The layout that was built, or the reason it could not be.
]]
function Generator:Create(p_RoomSource: Folder, p_GenerationData: Types.MapGenerationData): Result.Result<Types.MapGenerationResult, string>
    if typeof(p_RoomSource) ~= 'Instance' or not p_RoomSource:IsA('Folder') then
        return Result.new(nil, "Invalid given room source")
    end

    State = NewState()
    State.Source = p_RoomSource

    if not GetStartingRoom() then
        return Result.new(nil, 'No starting room in source: ' .. p_RoomSource:GetFullName());
    end

    local Seed = p_GenerationData.Seed or 0
    if Seed <= 0 then
        Seed = Random.new():NextInteger(1, MAX_SEED)
    end

    State.Seed = Seed
    State.Rng = Random.new(Seed)

    State.RoomLimit = math.max(p_GenerationData.Rooms or p_GenerationData.Extent or DEFAULT_ROOM_COUNT, 1)
    State.TileLimit = math.max(p_GenerationData.Extent or (State.RoomLimit * 2), State.RoomLimit)
    State.Infinite = p_GenerationData.Infinite == true
    State.Trail = p_GenerationData.Trail or 0

    ---
    local NewSpawnLocation = Instance.new("SpawnLocation")
    NewSpawnLocation.Transparency = 1
    NewSpawnLocation.Duration = 0;
    NewSpawnLocation.Size = vector.create(4, 1, 4)
    NewSpawnLocation.CFrame = BASE_CFRAME * CFrame.new(0, 2, 0)
    NewSpawnLocation.Parent = workspace

    CreateRoom();
    SealOpenConnectors();

    return Result.new({
        Seed = State.Seed,
        Rooms = State.Rooms,
        RoomCount = State.PlacedRooms,
        HallCount = State.PlacedHalls,
        SealCount = State.PlacedSeals,
    } :: Types.MapGenerationResult)
end

return Generator
