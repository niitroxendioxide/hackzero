--[[
    
@niitroxendioxide 2025-10
Used to procedurally generate maps using the given map data, such as map folder, rate, etc.

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Maps
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)

local MAX_DEFINED_ITER = 25

type RoomStruct = {
    Model: Model,
    Connections: { Part },
    Type: string,
}

type CreatedRoom = {
    Model: Model,
    RoomId: number,
    Available: { Instance },
    ConnectionParts: { Instance },
    Connections: { [number]: number },

    Links: { [number]: Part },
}

--
local Generator = {
    __Cached_Rooms = {} :: { RoomStruct },
    __Rooms = {} :: { CreatedRoom },
}

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

function PlaceRoom(p_Room: CreatedRoom)
    local SourceConnection = p_Room.Connections[1];
    if not SourceConnection then
        p_Room.Model:PivotTo(CFrame.new(0, 0, 0))

        return;
    end

    
    local RoomConnection = Generator.__Rooms[SourceConnection];
    
    local LinkObj = p_Room.Links[RoomConnection.RoomId]
    local OtherLinkObj = RoomConnection.Links[p_Room.RoomId]
    
    local RootOffset = (p_Room.Model.PrimaryPart :: BasePart).CFrame:ToObjectSpace(LinkObj.CFrame)
    local BaseOffset = OtherLinkObj.CFrame * CFrame.Angles(0, math.pi, 0)
    
    LinkObj.Color = Color3.new(1)
    OtherLinkObj.Color = Color3.new(1)
                    
    local NewCFrame = (BaseOffset * RootOffset)
    p_Room.Model:PivotTo(NewCFrame)

    local p = Instance.new("Part")
    p.Size = vector.create(3, 12, 3)
    p.CFrame = NewCFrame
    p.Anchored = true
    p.CanCollide = false
    p.Color = Color3.new(1, 0, 1)
    p.Parent = workspace.World.Effects
end

function GetRoomWithEnoughConnections(p_ConnectionCountMin: number): RoomStruct?
    for _, RoomData: RoomStruct in Generator.__Cached_Rooms do
        if #RoomData.Connections >= p_ConnectionCountMin then
            return RoomData
        end
    end

    return;
end

function IsTileAvailable(p_At: vector): boolean
    return false
end

function CreateRoomFromModel(p_Model: Model & { Connections: Folder }, p_Connection: number?): CreatedRoom?
    local s_Connection, s_Link;

    if p_Connection then
        s_Connection = Generator.__Rooms[p_Connection];
        if not s_Connection or #s_Connection.Available <= 0 then return end
    
        s_Link = s_Connection.Available[math.random(#s_Connection.Available)]
        table.remove(s_Connection.Available, table.find(s_Connection.Available, s_Link))
    end

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
    

    if s_Connection then
        local ConnectedAt = Object.Available[math.random(1, #Object.Available)]

        table.remove(Object.Available, table.find(Object.Available, ConnectedAt))

        table.insert(Object.Connections, s_Connection.RoomId)
        table.insert(s_Connection.Connections, Object.RoomId)

        Object.Links[s_Connection.RoomId] = ConnectedAt
        s_Connection.Links[Object.RoomId] = s_Link
    end


    table.insert(Generator.__Rooms, Object)

    PlaceRoom(Object)

    return Object
end

function Generator:Create(p_Folder: Folder, p_GenerationData: Types.MapGenerationData): (boolean, string?)
    local PossibleStartingRooms = {}
    local Source = GetRoomsSource(p_Folder, p_GenerationData.Source)
    if not Source then
        return false, "Source not found";
    end

    local Design = Instance.new("Folder")
    Design.Name = "Design"
    Design.Parent = workspace.World.Map

    for _, Child in Source:GetChildren() do
        if not Child:IsA("Model") then continue end

        if Child:HasTag("Room") then 
            table.insert(PossibleStartingRooms, Child)
        end

        table.insert(Generator.__Cached_Rooms, { 
            Model = Child,
            Connections = Child.Connections:GetChildren(),
            Type = Child:GetTags()[1],
        })
    end

    -- generated
    local InitialRoom = CreateRoomFromModel(PossibleStartingRooms[math.random(1, #PossibleStartingRooms)])

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
    end
end

-- for infinite maps
function Generator:Expand(Room: number)
    
end

return Generator