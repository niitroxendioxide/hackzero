--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


--- Constants
local SIZE_CONSTANT = 1 / 1.1
local RNG = Random.new()
local VIEW_TIME = 0.1
local TILE_SIZE = 64
local BASE_CFRAME = CFrame.new(0, 0, 0)
local TILE_OFFSET = CFrame.new(0, 0, -(TILE_SIZE / 2)) * CFrame.Angles(0, math.pi, 0)


--- Generator Related
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)
local Result = require(Shared.Utility.Result)

local Generator = {};
local State = {
    RoomRootParts = {},
    CurrentRoomId = 0,
    CurrentHallId = 0,
    Infinite = false,
    RoomLimit = 80,
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

    if State.CurrentRoomId + 1 > State.RoomLimit then
        return;
    end

    task.wait(VIEW_TIME)

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

    --
    for _, Connection in Clone.Connections:GetChildren() do
        local ConnectorCFrame = Connection.CFrame
        Connection:Destroy();

        CreateRoom(ConnectorCFrame * TILE_OFFSET, not UseHall)
    end
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
    NewSpawnLocation.Size = vector.create(4, 1, 4)
    NewSpawnLocation.CFrame = BASE_CFRAME * CFrame.new(0, 2, 0)
    NewSpawnLocation.Parent = workspace

    task.spawn(CreateRoom)

    return Result.new(true)
end

return Generator