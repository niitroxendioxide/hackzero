--[[
    @niitroxendioxide 2025-10
    Used to procedurally generate maps using the given map data, such as map folder, rate, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Stages)

-- Definitions
type Tile = {
    Position: vector,
    Occuppied: boolean,
    Occupant: number?,
}

type RoomTemplate = {
    Model: Model,
    ConnectionCount: number,
    Tags: { string },
}

type RoomStruct = {
    Id: number,
    Position: vector,
    Model: Model,
    AvailableConnections: { [vector] : Part },
    Connections: { [vector]: number },
    ConnectionCount: number,
    Destroy: (self: RoomStruct) -> ();
}


--
local TILE_SIZE = 76
local BASE_CFRAME = CFrame.new(0, 0, 0)
local Generator = {
    __Room_Counter = 0;
    __Tiles = {} :: { [vector]: Tile },
    __Room_List = {} :: { RoomStruct },
    __Room_Types = {} :: { RoomTemplate },
}


-- Privates
function Destroy(p_Self: RoomStruct)
    if (p_Self == nil) then return end;
    RemoveRoom(p_Self);

    p_Self.Model:Destroy();
end

function AddRoom(p_Room: RoomStruct)
    Generator.__Room_Counter += 1;
    p_Room.Id = Generator.__Room_Counter;

    Generator.__Room_List[Generator.__Room_Counter] = p_Room;
end

function RemoveRoom(p_Room: RoomStruct)
    Generator.__Room_List[p_Room.Id] = nil;
end

function GetTileAt(p_At: vector): Tile
    if Generator.__Tiles[p_At] then
        return Generator.__Tiles[p_At];
    end

    local NewTile = {
        Position = p_At,
        Occuppied = false,
        Occupant = nil,
    }

    Generator.__Tiles[p_At] = NewTile;

    return NewTile;
end

function PlaceRoom(p_Room: RoomStruct)
    local Position = p_Room.Position
    local Rotation = CFrame.Angles(0, math.rad(Position.z), 0)
    local ModelCFrame = (BASE_CFRAME) * CFrame.new(Position.x * TILE_SIZE, 0, Position.y * TILE_SIZE) * Rotation
    p_Room.Model:PivotTo(ModelCFrame)
end

function ProduceVectorConnections(p_Model: Model & {Connections: Folder}): {[vector]: Part}
    local Vector = {}
    
    for _, Connector in p_Model.Connections:GetChildren() do
        local Dir = (p_Model:GetPivot().Position - Connector.Position).Unit
        local Vec = vector.create(math.round(Dir.Z), -math.round(Dir.X))
        Connector.Name = 'connector_['..Vec.x..'; '..Vec.y..']'

        Vector[Vec] = Connector

    end

    return Vector
end

function CreateRoom(p_Template: RoomTemplate, p_At: vector): RoomStruct?
    local TileAtPos = GetTileAt(p_At);
    if TileAtPos.Occuppied then
        return nil;
    end
    
    --
    local ClonedModel = p_Template.Model:Clone();
    ClonedModel.Parent = workspace.World.Map.Design;

    local Room = {
        Id = nil,
        Position = p_At,
        Model = ClonedModel,
        AvailableConnections = {},
        Connections = {},
        Destroy = Destroy,
    }

    Room.AvailableConnections = ProduceVectorConnections(ClonedModel);
    Room.ConnectionCount = p_Template.ConnectionCount;

    PlaceRoom(Room)
    AddRoom(Room)

    ClonedModel.Name = 'ROOM_'..Room.Id

    TileAtPos.Occuppied = Room.Id;

    return Room
end

function ConnectRooms(p_Source: RoomStruct, p_New: RoomStruct, p_At: vector)
    local IsAvailable = p_Source.AvailableConnections[p_At] ~= nil
    if not IsAvailable then
        return
    end

    local ConnectorObj = p_Source.AvailableConnections[p_At]
    ConnectorObj.Color = Color3.new(1)

    print(ConnectorObj)

    p_Source.AvailableConnections[p_At] = nil;
    p_Source.Connections[p_At] = p_New.Id;

    local baseCF = p_New.Model:GetPivot()
    local sourceCF = p_Source.Model:GetPivot()

    while (true) do
        for Dir, Connector in p_New.AvailableConnections do
            local LookVec = CFrame.lookAt(baseCF.Position, Connector.Position).LookVector
            local RoomToRoomDir = CFrame.lookAt(sourceCF.Position, baseCF.Position).LookVector

            if (RoomToRoomDir:Dot(LookVec) > -0.1 and RoomToRoomDir:Dot(LookVec) < 0.1) then  
                local Angle = math.deg(math.atan2(baseCF.LookVector.X, baseCF.LookVector.Z))
                p_New.Connections[Dir] = p_Source.Id;
                p_New.Position = vector.create(p_New.Position.x, p_New.Position.x, Angle)
                
                PlaceRoom(p_New)

                Connector.Color = Color3.new(1)
                p_New.AvailableConnections[Dir] = nil;

                return
            end
        end

        baseCF *= CFrame.Angles(0, math.pi * 0.5, 0)
        p_New.Model:PivotTo(baseCF)

        p_New.AvailableConnections = ProduceVectorConnections(p_New.Model :: any)

        task.wait(1)
    end
end

function GetRoom(p_Id: number): RoomStruct?
    return Generator.__Room_List[p_Id];
end


function GetRoomWithMinConnections(p_MinConnections: number): RoomStruct?
    local List = {}
    for _, RoomData in Generator.__Room_Types do
        if RoomData.ConnectionCount >= p_MinConnections then
            table.insert(List, RoomData)
        end
    end

    if (#List == 0) then
        return  nil;
    end

    return List[math.random(1, #List)];
end

-- Publics
function Generator:CacheRooms(p_RoomSource: Folder): { RoomTemplate }
    Generator.__Room_Types = {};

    local PossibleStartingRooms = {}

    for _, Child in p_RoomSource:GetChildren() do
        if not Child:IsA("Model") then continue end

        local Connections = Child.Connections:GetChildren()
        local ConnectionCount = #Connections;

        local Template = { 
            Model = Child,
            ConnectionCount = ConnectionCount,
            Connections = ProduceVectorConnections(Child),
            Tags = Child:GetTags(),
        } :: RoomTemplate

        if Child:HasTag("Room") and (#Child.Connections:GetChildren() < 2) then 
            table.insert(PossibleStartingRooms, Template)
        end

        table.insert(Generator.__Room_Types, Template)
    end

    return PossibleStartingRooms;
end

function Generator:Create(p_RoomSource: Folder, p_GenerationData: Types.MapGenerationData): boolean
    local DesignFolder = workspace.World.Map:FindFirstChild('Design')
    if DesignFolder then
        DesignFolder:ClearAllChildren()
    else
        DesignFolder = Instance.new('Folder')
        DesignFolder.Name = 'Design'
        DesignFolder.Parent = workspace.World.Map
    end

    for x = -100, 100 do
        for y = -100, 100 do
            Generator.__Tiles[vector.create(x, y)] = {
                Position = vector.create(x, y),
                Occuppied = false,
                Occupant = nil,
            }
        end
    end

    local InitTemplates = Generator:CacheRooms(p_RoomSource);
    local RandomTemplate = InitTemplates[math.random(1, #InitTemplates)];

    --
    local InitialRoom = CreateRoom(RandomTemplate, vector.create(0, 0))

    Generator:Extend(InitialRoom.Id, 2)

    return true
end

function Generator:Extend(p_RoomId: number, p_IterCount: number)
    local Struct = GetRoom(p_RoomId);
    if not Struct or (p_IterCount <= 0) then
        return;
    end

    p_IterCount -= 1;


    local RoomConnections =  Struct.ConnectionCount;
    local MinConnections = math.max(Struct.ConnectionCount, 2);
    if (p_IterCount <= 0) then
        MinConnections = 1;
    end

    --
    for i = 1, RoomConnections do
        local Template = GetRoomWithMinConnections(MinConnections);
        if not Template then
            continue
        end

        local VecDir = next(Template.Connections);
        local Position = VecDir + Struct.Position;

        local NewRoom = CreateRoom(Template, Position);
        if not NewRoom then
            continue
        end

        ConnectRooms(Struct, NewRoom, VecDir)
        Generator:Extend(NewRoom.Id, p_IterCount)
    end

end

return Generator;