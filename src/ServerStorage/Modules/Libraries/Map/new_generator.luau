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

        if Candidate:HasTag('Hall') ~= Hall then
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

        local FirstConnector = Clone.Connections:GetChildren()[1]
        if not FirstConnector then
            return;
        end

        local FirstCFrame = FirstConnector.CFrame;
        FirstConnector:Destroy()

        CreateRoom(FirstCFrame * TILE_OFFSET, true);

        return;
    end

    local BoundParams = OverlapParams.new()
    BoundParams.FilterDescendantsInstances = {MapFolder}
    BoundParams.FilterType = Enum.RaycastFilterType.Include

    local PartsInBox = workspace:GetPartBoundsInBox(RoomCFrame, vector.create(TILE_SIZE/2, TILE_SIZE/2, TILE_SIZE/2), BoundParams)
    if #PartsInBox > 0 then
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

        CreateRoom(ConnectorCFrame * TILE_OFFSET, not UseHall)
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

    return Result.new({
        Seed = State.Seed,
        Rooms = State.Rooms,
        RoomCount = State.PlacedRooms,
        HallCount = State.PlacedHalls,
    } :: Types.MapGenerationResult)
end

return Generator
