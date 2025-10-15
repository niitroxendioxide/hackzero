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
    UsedConnectors: { [Part] : number },
    Extends: number,

    GetCF: (self: RoomStruct) -> (CFrame),
}

--
local RNG = Random.new()
local VIEW_TIME = 0.01
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
    if p_Room == nil then
        return;
    end
    Generator.__Room_List[p_Room.Id] = nil;

    p_Room.Model:Destroy()
    p_Room.Model = nil
end

function RemoveLast()
    local Last = Generator.__Room_Counter
    local StructLast = Generator.__Room_List[Last]
    if StructLast.Extends ~= 0 then
        local SourceRoom = Generator.__Room_List[StructLast.Extends]
        local ConnectorExtended = nil;
        for Connector, RoomConnectedId in SourceRoom.UsedConnectors do
            if RoomConnectedId == Last then
                ConnectorExtended = Connector;
                break
            end
        end

        if ConnectorExtended then
            table.insert(SourceRoom.Connectors, ConnectorExtended);
            SourceRoom.UsedConnectors[ConnectorExtended] = nil
        end
    end

    Generator.__Room_List[Last] = nil;
    Generator.__Room_Counter = Last - 1;

    StructLast.Model:Destroy()
    StructLast.Model = nil
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

    return List[RNG:NextInteger(1, #List)];
end


-- Debug

function ShowDirection(p_Cf: CFrame, name)

    local fold = workspace:FindFirstChild("arrows") or Instance.new("Folder")
    fold.Name = 'arrows'
    fold.Parent = workspace

    local Part = Instance.new('Part')
    Part.Size = Vector3.one * 3
    Part.CFrame = p_Cf * CFrame.new(0, 2, -5)
    Part.Anchored = true
    Part.Name = name or 'arrow'
    Part.Shape = Enum.PartType.Ball
    Part.Color = Color3.new(0, 1, 1)
    Part.Parent = workspace:FindFirstChild("arrows")

    local Adornment = Instance.new('ConeHandleAdornment')
    Adornment.Adornee = Part
    Adornment.Height = 24
    Adornment.AlwaysOnTop = true
    Adornment.Parent = Part

    return Part
end

function ClearArrows()
    local ar = workspace:FindFirstChild("arrows")
    if ar then
        ar:ClearAllChildren()
    end
end

---
function IsRoomOnCFrame(p_CFrame: CFrame): (boolean, number?)

    for _, Room in Generator.__Room_List do
        if not Room.Model or not Room.Model:IsDescendantOf(workspace.World.Map.Design) then continue end

        local CF = Room:GetCF()
        local Distance = (CF.Position - p_CFrame.Position).Magnitude

        if Distance < TILE_SIZE * 0.1 then
            return true, Room.Id
        end
    end

    return false
end

function IsRoomOnDirection(p_Origin: RoomStruct, p_ConnectorCF: CFrame, p_TileMinimum: number?): boolean
    local Found = false
    local RoomId = nil
    local TotalDistance = math.huge
    local Minimum = p_TileMinimum or 25

    for _, Room in Generator.__Room_List do
        if Room == p_Origin or not Room.Model or not Room.Model:IsDescendantOf(workspace.World.Map.Design) then continue end

        local Distance = (Room:GetCF().Position - p_Origin:GetCF().Position).Magnitude
        local LV = CFrame.lookAt(p_Origin:GetCF().Position, Room:GetCF().Position).LookVector
        local Direction = p_ConnectorCF.LookVector:Dot(LV)

        if (Direction >= 1) and (TotalDistance > Distance) then
            Found = true
            RoomId = Room.Id
            TotalDistance = Distance
        end
    end

    if Found and (TotalDistance < (TILE_SIZE * Minimum)) then
        print('There is a tile in that direction!')
        ShowDirection(p_ConnectorCF, 'Obstruction for struct: ' .. p_Origin.Model.Name)

        return Found, RoomId
    end

    return false
end

function ConnectRoom(p_RoomSource: RoomStruct, p_RoomNew: RoomStruct, p_SuccessRoomId: number, p_OnlyFreeDirections: boolean?)
    --
    --ClearArrows()

    local SourceConnector = p_RoomSource.Connectors[RNG:NextInteger(1, #p_RoomSource.Connectors)]
    SourceConnector.Color = Color3.new(1)
    SourceConnector.CanTouch = false
    SourceConnector.CanQuery = false

    p_RoomNew.Model:PivotTo(SourceConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2))

    local Base = p_RoomNew:GetCF()
    local Fallback = {}

    --
    for i = -4, 4 do
        local RoomCF = p_RoomNew:GetCF()
        for key, Connector in p_RoomNew.Connectors do
            local LookVec = CFrame.lookAt(Connector.Position, RoomCF.Position)
            local RoomToRoomDir = CFrame.lookAt(SourceConnector.Position, RoomCF.Position)

            local Distance = RoomToRoomDir.LookVector:Dot(LookVec.LookVector)

            if (Distance >= 1) then
                local CanJoin = true;
                local HasFutureObstruction = false;

                local Next, _ = IsRoomOnDirection(p_RoomNew, SourceConnector.CFrame, 70)
                if Next then
                    --if p_OnlyFreeDirections then
                       -- CanJoin = false
                       -- continue
                    --end
                    continue
                end

                for _, OtherConnector in p_RoomNew.Connectors do
                    if (OtherConnector == Connector) then continue end
                    if not CanJoin then break end
                    
                    local OtherCF = OtherConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2)
                    if IsRoomOnCFrame(OtherCF) then
                        CanJoin = false;
                        break
                    end

                    local Limit = p_OnlyFreeDirections and 100000 or nil
                    local DirectionCollide, RoomId = IsRoomOnDirection(p_RoomNew, OtherConnector.CFrame, Limit)
                    if DirectionCollide then
                        HasFutureObstruction = true;

                        if p_OnlyFreeDirections then
                            CanJoin = false
                        end

                        continue
                    end

                    local FreeDirections = 0
                    for i = -1, 1 do
                        local Extend = OtherConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE)
                        local NextRoom = (Extend * CFrame.Angles(0, math.pi * 0.5 * i, 0)) * CFrame.new(0, 0, -(TILE_SIZE/2))

                        local IsOccupied, ri = IsRoomOnCFrame(NextRoom)
                        if not IsOccupied then
                            FreeDirections += 1
                            --print(RoomId, ' obstructing prediction for next room.')
                        end
                    end

                    if FreeDirections < 2 then
                        CanJoin = false;
                        break
                        --print(p_RoomSource.Id + 1, ' has directions free:', FreeDirections)
                    end
                end

                if not CanJoin then continue end
                if HasFutureObstruction and not p_OnlyFreeDirections then
                    Fallback = {
                        f_Cf = RoomCF,
                        f_Connector = Connector,
                    }

                    continue
                end

                SourceConnector.Transparency = 1
                Connector.Transparency = 1
                Connector.CanTouch = false
                Connector.CanQuery = false

                table.remove(p_RoomNew.Connectors, key)
                table.remove(p_RoomSource.Connectors, table.find(p_RoomSource.Connectors, SourceConnector))

                p_RoomNew.Extends = p_RoomSource.Id;
                p_RoomSource.UsedConnectors[SourceConnector] = p_SuccessRoomId

                return true;
            end
        end

        p_RoomNew.Model:PivotTo(Base * CFrame.Angles(0, math.pi * 0.5 * i, 0))
        task.wait(VIEW_TIME)
    end

    if Fallback.f_Connector and typeof(Fallback.f_Cf) == 'CFrame' then
        local AllConnectors = p_RoomNew.Connectors
        local Id = table.find(AllConnectors, Fallback.f_Connector)
        if not Id then
            return false;
        end

        table.remove(AllConnectors, Id)
        table.remove(p_RoomSource.Connectors, table.find(p_RoomSource.Connectors, SourceConnector))
        p_RoomNew.Extends = p_RoomSource.Id;
        p_RoomSource.UsedConnectors[SourceConnector] = p_SuccessRoomId

        p_RoomNew.Model:PivotTo(Fallback.f_Cf)
        return true;
    end

    return false
end


function CreateRoom(p_Model: RoomTemplate, p_ConnectedToId: number?, p_OnlyFreeDirections: boolean?): (boolean | RoomStruct | nil)
    if not p_Model then
        return nil;
    end

    local Cloned = p_Model.Model:Clone()
    Cloned.Parent = workspace.World.Map.Design

    local Latestid = Generator.__Room_Counter + 1
    local Room = {
        Id = 0,
        Model = Cloned,
        Connectors = Cloned.Connections:GetChildren(),
        UsedConnectors = {},
        Extends = 0,

        GetCF = function(self: RoomStruct)
            return self.Model:GetPivot();
        end
    }

    for _, connector in Room.Connectors do
        connector.CanCollide = false
        connector.CanTouch = false
        connector.CanQuery = false
    end

    if p_ConnectedToId then
        local CouldConnect = ConnectRoom(GetRoom(p_ConnectedToId), Room, Latestid, p_OnlyFreeDirections)
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
    local RandomTemplate = InitTemplates[RNG:NextInteger(1, #InitTemplates)];

    --
    CreateRoom(RandomTemplate)

    --
    local trail = 15
    local max = (p_GenerationData.Infinite and 2500) or p_GenerationData.Extent
    if max == nil then
        return false,  "Extent is required for non-infinite generations"
    end

    if p_GenerationData.Seed ~= 0 then
        RNG = Random.new(p_GenerationData.Seed)
    end

    local function extend(i, list, onlyfreedir)
        task.wait(VIEW_TIME)
        if (i > max) then
            return;
        end

        local Template = GetRoomWithMinConnections(2, list)
        local Created = CreateRoom(Template, i, onlyfreedir)
        if Created == false then
            if onlyfreedir then
                RemoveLast()
                extend(i - 1, list, true)

                return;
            end

            local new_list = list or {}
            table.insert(new_list, Template)
            
            extend(i, new_list)

            return;
        elseif Created == nil and i < max then
            if onlyfreedir then
                return;
            end

            RemoveLast()
            extend(i - 1, {}, true);

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

return Generator