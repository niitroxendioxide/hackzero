--[[
    @niitroxendioxide 2025-10
    Used to procedurally generate maps using the given map data, such as map folder, rate, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules.Shared

local Print = require(ReplicatedStorage.Modules.Shared.Utility.Print)
local Types = require(Shared.Types.Stages)

-- Definitions
type RoomTemplate = {
    ConnectionCount: number,
    Tags: { string },
    Model: Model,
}

type RoomStruct = {
    [string]: any,

    Model: Model,
    Connectors: { Part },

    GetCF: (self: RoomStruct) -> (CFrame),
}

--
local VIEW_TIME = 0.1
local TILE_SIZE = 76
local BASE_CFRAME = CFrame.new(0, 0, 0)
local Generator = {
    __Room_Counter = 0;
    __Room_List = {},
    __Room_Types = {} :: { RoomTemplate },
}


-- Privates
function AddRoom(p_Room)
    local NewId = Generator.__Room_Counter + 1
    Generator.__Room_Counter=NewId;

    p_Room.Id = NewId;
    p_Room.Model.Name = 'Room_'..tostring(NewId)
    Generator.__Room_List[NewId] = p_Room;
end

function RemoveRoom(p_Room)
    Generator.__Room_List[p_Room.Id] = nil;

    p_Room.Model:Destroy()
    p_Room.Model = nil
end

function GetRoom(p_Id: number)
    return Generator.__Room_List[p_Id];
end

function GetRoomWithMinConnections(p_MinConnections: number, Ignore: { RoomTemplate }?): RoomTemplate?
    local List = {}
    Ignore = Ignore or {}
    for _, RoomData in Generator.__Room_Types do
        if RoomData.ConnectionCount >= p_MinConnections and not table.find(Ignore :: { RoomTemplate }, RoomData) then
            table.insert(List, RoomData)
        end
    end

    if (#List == 0) then
        return nil;
    end

    return List[math.random(1, #List)];
end

---
function IsRoomOnCFrame(p_CFrame: CFrame): boolean

    for _, Room in Generator.__Room_List do
        if not Room.Model or not Room.Model:IsDescendantOf(workspace.World.Map.Design) then continue end

        local CF = Room:GetCF()
        local Distance = (CF.Position - p_CFrame.Position).Magnitude

        if Distance < TILE_SIZE * 0.1 then
            return true
        end
    end

    return false
end

function ConnectRoom(p_RoomSource: RoomStruct, p_RoomNew: RoomStruct)
    --

    local SourceConnector = p_RoomSource.Connectors[math.random(1, #p_RoomSource.Connectors)]
    SourceConnector.Color = Color3.new(1)
    SourceConnector.CanTouch = false
    SourceConnector.CanQuery = false

    p_RoomNew.Model:PivotTo(SourceConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2))

    --
    for i = 1, 8 do
        local RoomCF = p_RoomNew:GetCF()
        for key, Connector in p_RoomNew.Connectors do
            local LookVec = CFrame.lookAt(Connector.Position, RoomCF.Position)
            local RoomToRoomDir = CFrame.lookAt(SourceConnector.Position, RoomCF.Position)

            local Distance = RoomToRoomDir.LookVector:Dot(LookVec.LookVector)

            if (Distance >= 1) then
                local CanJoin = true;

                for _, OtherConnector in p_RoomNew.Connectors do
                    if (OtherConnector == Connector) then continue end
                    if not CanJoin then break end
                    
                    local OtherCF = OtherConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2)
                    if IsRoomOnCFrame(OtherCF) then
                        CanJoin = false;
                        break
                    end
                end

                if not CanJoin then continue end

                SourceConnector.Transparency = 1
                Connector.Transparency = 1
                Connector.CanTouch = false
                Connector.CanQuery = false

                table.remove(p_RoomNew.Connectors, key)
                table.remove(p_RoomSource.Connectors, table.find(p_RoomSource.Connectors, SourceConnector))

                return true;
            end
        end

        p_RoomNew.Model:PivotTo(RoomCF * CFrame.Angles(0, math.pi * 0.5, 0))
        task.wait(VIEW_TIME)
    end

    return false
end

function CreateRoom(p_Model: RoomTemplate, p_ConnectedToId: number?): (boolean | RoomStruct | nil)
    if not p_Model then
        return nil;
    end

    local Cloned = p_Model.Model:Clone()
    Cloned.Parent = workspace.World.Map.Design

    local Room = {
        Id = 0,
        Model = Cloned,
        Connectors = Cloned.Connections:GetChildren(),

        GetCF = function(self: RoomStruct)
            return self.Model:GetPivot();
        end
    }

    if p_ConnectedToId then
        local CouldConnect = ConnectRoom(GetRoom(p_ConnectedToId), Room)
        if not CouldConnect then
            Cloned:Destroy()

            return false
        end
    else
        Cloned:PivotTo(BASE_CFRAME)
    end

    --
    AddRoom(Room)

    return Room
end


---
function Generator:CacheRooms(p_RoomSource: Folder): { RoomTemplate }
    Generator.__Room_Types = {};

    local PossibleStartingRooms = {}

    for _, Child in p_RoomSource:GetChildren() do
        if not Child:IsA("Model") then continue end

        local ConnectionCount = #Child.Connections:GetChildren();

        local Template = { 
            Model = Child,
            ConnectionCount = ConnectionCount,
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

    local InitTemplates = Generator:CacheRooms(p_RoomSource);
    local RandomTemplate = InitTemplates[math.random(1, #InitTemplates)];

    --
    CreateRoom(RandomTemplate)

    --
    local trail = 5000
    local max = 35
    local function extend(i, list)
        task.wait(VIEW_TIME)
        if (i > max) then
            return;
        end

        local Template = GetRoomWithMinConnections(2, list)
        local Created = CreateRoom(Template, i)
        if Created == false then
            local new_list = list or {}
            table.insert(new_list, Template)
            
            extend(i, new_list)

            return;
        elseif Created == nil then
            Template = GetRoomWithMinConnections(1, list)
            local Success = CreateRoom(Template, i)

            return;
        end

        if (i > trail) then
            local OldRoom = GetRoom(i - trail)
            RemoveRoom(OldRoom)
        end

        i += 1;
        extend(i)
    end

    task.spawn(extend, 1)

    return true
end

--[[function Generator:Extend(p_CurrentIndex: number, p_Max: number)
    if (p_CurrentIndex > p_Max) then return end

    local Template = GetRoomWithMinConnections(2)
    CreateRoom(Template, p_CurrentIndex)
    
    p_CurrentIndex += 1;

    Generator:Extend(p_CurrentIndex, p_Max)
    
end]]

return Generator