--[[
    
@niitroxendioxide 2025-10
Used to procedurally generate maps using the given map data, such as map folder, rate, etc.

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Maps
local Shared = ReplicatedStorage.Modules.Shared
local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Stages)

local MAX_DEFINED_ITER = 25
local TILE_SIZE = 76

type RoomStruct = {
    Model: Model,
    Connections: { Part },
    Type: string,
}

type CreatedRoom = {
    Position: vector,
    Model: Model,
    RoomId: number,
    Available: { Instance },
    ConnectionParts: { Instance },
    Connections: { [number]: number },

    Links: { [number]: Part },
}

--
local Generator = {
    __Origin =  nil  :: CreatedRoom?,
    __Cached_Rooms = {} :: { RoomStruct },
    __Rooms = {} :: { CreatedRoom },
}

function CalculateRoomPosition(p_At: Vector3): vector
    local OffsetFromOrigin = p_At - Generator.__Origin.Model:GetPivot().Position
    local X = math.round(OffsetFromOrigin.X / TILE_SIZE)
    local Y = math.round(OffsetFromOrigin.Y / TILE_SIZE)
    local CreatedVec2 = vector.create(X, Y)

    return CreatedVec2
end

function GetRoomsSource(p_MapFolder: Folder, p_Source: string): Folder?
    local SourceDirs = string.split(p_Source, '/')
    local MapFolder = p_MapFolder
    local index = 1;

    if SourceDirs[1] == 'Maps' then
        MapFolder = Assets
        index = 2
    end

    for i = index, #SourceDirs do
        MapFolder = MapFolder:FindFirstChild(SourceDirs[i])
        if MapFolder == nil then
            return nil
        end
    end

    return MapFolder
end

function PlaceRoom(p_Room: CreatedRoom, p_Connection: number?): boolean
    if not p_Connection then
        p_Room.Model:PivotTo(CFrame.new(0, 0, 0))

        return true;
    end

    local CurrentRoom = p_Room
    local OtherRoom = Generator.__Rooms[p_Connection]

    local c_idx = 1;
    local o_idx = 1;

    local OtherRoomConnector = OtherRoom.Available[o_idx]
    local CurrentRoomConnector = CurrentRoom.Available[c_idx]
    
    while (true) do
        local NewCFrame = OtherRoom.Model:GetPivot() * CFrame.new(0, 0, TILE_SIZE) --(BaseOffset * RootOffset)

        p_Room.Model:PivotTo(NewCFrame)
        
        break
    end

    table.remove(CurrentRoom.Available, table.find(CurrentRoom.Available, CurrentRoomConnector))
    table.remove(OtherRoom.Available, table.find(OtherRoom.Available, OtherRoomConnector))

    -- set up backwards connections
    table.insert(CurrentRoom.Connections, OtherRoom.RoomId)
    table.insert(OtherRoom.Connections, CurrentRoom.RoomId)

    CurrentRoomConnector.Color = Color3.new(1)
    OtherRoomConnector.Color = Color3.new(1)

    p_Room.Model.Name = tostring(p_Room.RoomId)

    CurrentRoom.Links[OtherRoom.RoomId] = CurrentRoomConnector
    OtherRoom.Links[CurrentRoom.RoomId] = OtherRoomConnector

    return true;
end


function GetRoomWithEnoughConnections(p_ConnectionCountMin: number): RoomStruct?
    local List = {}

    for _, RoomData: RoomStruct in Generator.__Cached_Rooms do
        if #RoomData.Connections >= p_ConnectionCountMin then
            table.insert(List, RoomData)
        end
    end

    return Table.PopRandom(List);
end

function IsTileAvailable(p_At: Vector3, p_RoomIgnore: CreatedRoom): boolean
    local MAX_DIST = TILE_SIZE / math.sin(math.pi * 0.25)
    
    for _, Room in Generator.__Rooms do
        local dist = (Room.Model:GetPivot().Position - p_At).Magnitude
        if dist < MAX_DIST and Room ~= p_RoomIgnore then
            return false
        end
    end

    return true
end

function CreateRoomFromModel(p_Model: Model & { Connections: Folder }, p_Connection: number?): CreatedRoom?
    if p_Connection and #Generator.__Rooms[p_Connection].Available <= 0 then return end

    --
    local ObjModel = p_Model:Clone()
    ObjModel.Parent = workspace.World.Map.Design;
    
    local Object = {
        Model = ObjModel,
        Available = ObjModel.Connections:GetChildren(),
        ConnectionParts = ObjModel.Connections:GetChildren(),

        RoomId = #Generator.__Rooms + 1,
        Connections = {},
        Links = {},
    } :: CreatedRoom;
    

    local Success = PlaceRoom(Object, p_Connection)
    if not Success then
        print('SUCCESS STATUS:', Success)

        return nil;
    end


    table.insert(Generator.__Rooms, Object)

    return Object
end

function Generator:Create(p_Folder: Folder, p_GenerationData: Types.MapGenerationData): (boolean, string?)
    local PossibleStartingRooms = {}
    local Source = GetRoomsSource(p_Folder, p_GenerationData.Source)
    if not Source then
        return false, "Source not found";
    end

    if workspace.World.Map:FindFirstChild('Design') then
        return false, "Map already has a Design folder"
    end

    local Design = Instance.new("Folder")
    Design.Name = "Design"
    Design.Parent = workspace.World.Map

    for _, Child in Source:GetChildren() do
        if not Child:IsA("Model") then continue end

        if Child:HasTag("Room") and (#Child.Connections:GetChildren() < 2) then 
            table.insert(PossibleStartingRooms, Child)
        end

        local obj = { 
            Model = Child,
            Connections = Child.Connections:GetChildren(),
            Type = Child:GetTags()[1],
        }

        for i = 1, #obj.Connections do
            obj.Connections[i].Name = 'Connector: ' .. i
        end

        table.insert(Generator.__Cached_Rooms, obj)
    end

    -- generated
    local InitialRoom = CreateRoomFromModel(PossibleStartingRooms[math.random(1, #PossibleStartingRooms)])
    Generator.__Origin = InitialRoom

    Generator:Connect(InitialRoom, 2, 0)
    
    return true
end

function Generator:Connect(p_BaseRoom: CreatedRoom, p_MinConnections: number, p_IterCount: number)
    --- take the base room, grab a room with min connection amount and then xpand on it
    p_IterCount = p_IterCount or 0

    if p_IterCount >= MAX_DEFINED_ITER then
        return
    end

    local ConnectionsToCreate = #p_BaseRoom.Available

    for i = 1, ConnectionsToCreate do
        p_IterCount += 1;

        local Room = GetRoomWithEnoughConnections(p_MinConnections)
        local GeneratedRoom = CreateRoomFromModel(Room.Model, p_BaseRoom.RoomId)

        Generator:Connect(GeneratedRoom, p_MinConnections, p_IterCount)

        task.wait(1)
    end
end

-- for infinite maps
function Generator:Expand(Room: number)
    
end

return Generator