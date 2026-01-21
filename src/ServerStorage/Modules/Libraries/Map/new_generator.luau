--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")


--- Constants
local SIZE_CONSTANT = 1 / 1.1
local RNG = Random.new()
local VIEW_TIME = 0.01
local TILE_SIZE = 96
local BASE_CFRAME = CFrame.new(0, 0, 0)
local TILE_OFFSET = CFrame.new(0, 0, -(TILE_SIZE / 2)) * CFrame.Angles(0, math.pi, 0)
local TILE_AREA_SIZE = vector.create(TILE_SIZE, TILE_SIZE, TILE_SIZE)


--- Generator Related
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)
local Result = require(Shared.Utility.Result)

local Generator = {};
local State = {
    Rooms = {},
    RoomCount = 0,
    RoomRootParts = {},
    CurrentRoomId = 0,
    CurrentHallId = 0,
    Infinite = false,
    RoomLimit = 80,
    TrailingRooms = 25,
    Source = nil,
};

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

local function ChooseFromSource(IsStarting: boolean, Hall: boolean, IsFinished: boolean?)
    local RoomSource = State.Source;
    if not RoomSource then
        return;
    end

    local StartingRoom = RoomSource:FindFirstChild('StartingRoom')
    if IsStarting then
        return StartingRoom
    end

    local Rooms = RoomSource:GetChildren();

    table.remove(Rooms, table.find(Rooms, StartingRoom))

    for k = #Rooms, 1, -1 do
        local RoomIsHall = Rooms[k]:HasTag('Hall')
        if not RoomIsHall and Hall then
            table.remove(Rooms, k)
            continue
        elseif RoomIsHall and not Hall then
            table.remove(Rooms, k)
            continue
        end

        if not IsFinished and #Rooms[k].Connections:GetChildren() < 1 then
            table.remove(Rooms, k)
        end
    end

    return Rooms[RNG:NextInteger(1, #Rooms)]
end

function CreateRoom(RoomCFrame: CFrame?, UseHall: boolean)
    local IsStarting = State.CurrentRoomId <= 0
    local MapFolder = GetMapFolder()
    local IsFinished = (State.CurrentRoomId + 1) == State.RoomLimit
    local BaseRoom = ChooseFromSource(IsStarting, UseHall, IsFinished);
    BaseRoom.PrimaryPart.Transparency = 1;

    State.RoomCount += 1;

    if State.CurrentRoomId + 1 > State.RoomLimit then
        return;
    end

    if RunService:IsStudio() then
        task.wait(VIEW_TIME)
    end

    if IsStarting then
        local FirstAngle = RNG:NextInteger(0, 3) * (math.pi / 2)
        local Clone = BaseRoom:Clone();
        Clone:PivotTo(BASE_CFRAME * CFrame.Angles(0, FirstAngle, 0))
        Clone.Parent = MapFolder

        State.CurrentRoomId = 1;

        local FirstConnector = Clone.Connections:GetChildren()[1]
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
    if  UseHall then
        State.CurrentHallId += 1
    end

    local Clone = BaseRoom:Clone();
    Clone:PivotTo(RoomCFrame);
    if UseHall then
        Clone.Name = 'Hall_' .. State.CurrentHallId
    else
        Clone.Name = 'Room_' .. State.CurrentRoomId // 2
    end

    Clone.Parent = MapFolder;

    table.insert(State.RoomRootParts, Clone.PrimaryPart)

    State.CurrentRoomId += 1;
    local SelfRoomId = State.CurrentRoomId // 2;

    State.Rooms[State.CurrentRoomId] = {
        Model = Clone,
        Id = SelfRoomId,
    }

    --
    for _, Connection in Clone.Connections:GetChildren() do
        local ConnectorCFrame = Connection.CFrame
        Connection:Destroy();

        CreateRoom(ConnectorCFrame * TILE_OFFSET, not UseHall)
    end

    ---
    if not UseHall then
        CreateTriggerPart(Clone, SelfRoomId)
    end
end

function CreateTriggerPart(BaseRoom: Model, Id: number)
    local MarkerFolder = workspace.World.Map:FindFirstChild("Markers")
    if not MarkerFolder then
        MarkerFolder = Instance.new("Folder")
        MarkerFolder.Name = 'Markers'
        MarkerFolder.Parent = workspace.World.Map
    end

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
    NewMarker.Parent = MarkerFolder
    NewMarker:SetAttribute("AreaSize", TILE_AREA_SIZE)
    
end

--- Public
function Generator:Create(p_RoomSource: Folder, p_GenerationData: Types.MapGenerationData): Result.Result<boolean, string>
    if typeof(p_RoomSource) ~= 'Instance' or not p_RoomSource:IsA('Folder') then
        return Result.new(nil, "Invalid given room source")
    end
    
    if p_GenerationData.Seed and p_GenerationData.Seed > 0 then
        RNG = Random.new(p_GenerationData.Seed)
    end

    ---
    State.RoomLimit = (p_GenerationData.Extent or 50)
    State.Infinite = p_GenerationData.Infinite
    State.Source = p_RoomSource

    local StartingRoomObject = ChooseFromSource(true)

    if not StartingRoomObject then
        return Result.new(nil, 'No starting room given');
    end

    ---
    local NewSpawnLocation = Instance.new("SpawnLocation")
    NewSpawnLocation.Transparency = 1
    NewSpawnLocation.Size = vector.create(4, 1, 4)
    NewSpawnLocation.CFrame = BASE_CFRAME * CFrame.new(0, 2, 0)
    NewSpawnLocation.Parent = workspace

    CreateRoom();

    return Result.new(true)
end

return Generator