--[[
    @niitroxendioxide 2025-10
    Used to procedurally generate maps using the given map data, such as map folder, rate, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules.Shared

local _Print = require(ReplicatedStorage.Modules.Shared.Utility.Print)
local Types = require(Shared.Types.Stages)

-- Definitions
type RoomTemplate = {
    ConnectionCount: number,
    Tags: { string },
    Model: Model,
}

type RoomStruct = {
    Id: number,
    Tags: { string }, 
    Model: Model,
    Connectors: { Part },
    UsedConnectors: { [Part] : number },
    Extends: number,

    GetCF: (self: RoomStruct) -> (CFrame),
}

--
local RNG = Random.new()
local VIEW_TIME = 0.1
local TILE_SIZE = 76
local BASE_CFRAME = CFrame.new(0, 0, 0)
local Generator = {
    __Infinite = false  :: boolean,
    __Side = -1         :: number,
    __Debug = false     :: boolean,
    __Room_Count = 0    :: number,
    __Trail = math.huge :: number,
    __Max = 0           :: number,
    __Room_Counter = 0  :: number;
    __Room_List = {}    :: { RoomStruct },
    __Room_Types = {}   :: { RoomTemplate },
}


-- Privates
function AddRoom(p_Room)
    local NewId = Generator.__Room_Counter + 1
    Generator.__Room_Counter=NewId;

    p_Room.Id = NewId;
    p_Room.Model.Name = 'Room_'..tostring(NewId)
    Generator.__Room_List[NewId] = p_Room;

    Generator.__Room_Count += 1
end

function RemoveRoom(p_Room)
    if p_Room == nil then
        return;
    end
    Generator.__Room_List[p_Room.Id] = nil;

    p_Room.Model:Destroy()
    p_Room.Model = nil

    Generator.__Room_Count -= 1
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

function GetRoomWithMinConnections(p_MinConnections: number, Ignore: { RoomTemplate }?, exludeTags: { [string]: boolean }?): RoomTemplate?
    local List = {}
    Ignore = Ignore or {}
    
    for _, RoomData in Generator.__Room_Types do
        local skip = false;
        if exludeTags :: { [string]: boolean } then
            for _, t in RoomData.Tags do
                if exludeTags[t] then skip = true; break end
            end
            if skip then continue end
        end

        if RoomData.ConnectionCount >= p_MinConnections and not table.find(Ignore :: { RoomTemplate }, RoomData) then
            table.insert(List, RoomData)
        end
    end

    if (#List == 0) then
        return nil;
    end

    return List[RNG:NextInteger(1, #List)];
end


function GetRoomsWithConnectionCount(p_ConnectionCount: number): RoomTemplate?
    local List = {}
    
    for _, RoomData in Generator.__Room_Types do
        if RoomData.ConnectionCount == p_ConnectionCount then
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

function _ClearArrows()
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
        if Generator.__Debug then
            ShowDirection(p_ConnectorCF, 'Obstruction for struct: ' .. p_Origin.Model.Name)
        end

        return Found, RoomId
    end

    return false
end

function ConnectRoom(p_RoomSource: RoomStruct, p_RoomNew: RoomStruct, p_SuccessRoomId: number, p_OnlyFreeDirections: boolean?)
    --
    --ClearArrows()
    local SourceConnector = p_RoomSource.Connectors[RNG:NextInteger(1, #p_RoomSource.Connectors)]
    if not SourceConnector then
        return false;
    end
    
    SourceConnector.Color = Color3.new(1)
    SourceConnector.CanTouch = false
    SourceConnector.CanQuery = false

    p_RoomNew.Model:PivotTo(SourceConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2))

    local Base = p_RoomNew:GetCF()
    local Fallback = {}

    --
    local IsOneConnector = #p_RoomNew.Connectors == 1
    for i = 0, Generator.__Side * 8, Generator.__Side do
        local RoomCF = p_RoomNew:GetCF()
        for key, Connector in p_RoomNew.Connectors do
            local LookVec = CFrame.lookAt(Connector.Position, RoomCF.Position)
            local RoomToRoomDir = CFrame.lookAt(SourceConnector.Position, RoomCF.Position)

            local Distance = RoomToRoomDir.LookVector:Dot(LookVec.LookVector)

            if (Distance >= 1) then
                local CanJoin = true;
                local HasFutureObstruction = false;

                local Next, _ = IsRoomOnDirection(p_RoomNew, SourceConnector.CFrame, IsOneConnector and 1 or 70)
                if Next then
                    if Generator.__Debug then
                        print(p_RoomSource.Id, ' has directions obstructed!')
                    end
                    --if p_OnlyFreeDirections then
                       -- CanJoin = false
                       -- continue
                    --end
                    continue
                end

                for _, OtherConnector in p_RoomNew.Connectors do
                    if (OtherConnector == Connector) then continue end
                    if not CanJoin then break end

                    if Generator.__Debug then
                        print(p_RoomSource.Id, ' obstructing prediction for next room.')
                    end
                    
                    local OtherCF = OtherConnector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2)
                    if IsRoomOnCFrame(OtherCF) then
                        CanJoin = false;
                        break
                    end

                    local Limit = p_OnlyFreeDirections and 100000 or (IsOneConnector and 1 or nil)
                    local DirectionCollide, _RoomId = IsRoomOnDirection(p_RoomNew, OtherConnector.CFrame, Limit)
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

                        local IsOccupied, _ = IsRoomOnCFrame(NextRoom)
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

                    if Generator.__Debug then
                        print('Setup fallback')
                    end

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

    local ToFallback = IsOneConnector and not IsRoomOnCFrame(p_RoomNew:GetCF())
    if ToFallback then
        Fallback = {
            f_Cf = p_RoomNew:GetCF(),
            f_Connector = p_RoomNew.Connectors[1],
        }
    end

    if (Fallback.f_Connector and typeof(Fallback.f_Cf) == 'CFrame') then
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
        Id = Generator.__Room_Count + 1,
        Model = Cloned,
        Connectors = Cloned.Connections:GetChildren(),
        UsedConnectors = {},
        Extends = 0,
        Tags = p_Model.Tags,

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
        local RoomConnectedTo = GetRoom(p_ConnectedToId)
        if RoomConnectedTo == nil then
            Cloned:Destroy()

            return false
        end

        local CouldConnect = ConnectRoom(RoomConnectedTo, Room, Latestid, p_OnlyFreeDirections)
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
    local Trail = p_GenerationData.Trail or math.huge
    local MaximumRoomCount = (p_GenerationData.Infinite and 10000) or p_GenerationData.Extent
    if MaximumRoomCount == nil then
        return false,  "Extent is required for non-infinite generations"
    end

    if p_GenerationData.Seed ~= 0 then
        RNG = Random.new(p_GenerationData.Seed)
    end

    if p_GenerationData.Infinite and not Trail then
        return false, "Trail is required for infinite generations"
    end

    Generator.__Infinite = p_GenerationData.Infinite
    Generator.__Side = RNG:NextInteger(0, 1) == 0 and -1 or 1
    Generator.__Trail = p_GenerationData.Infinite and Trail or math.huge;
    Generator.__Max = MaximumRoomCount;

    Generator:Generate(1)

    if not p_GenerationData.Infinite and Generator.__Room_Counter >= Generator.__Max then
        --Generator.__Debug = true
        Generator:CompleteThirdPathRooms()
    end

    return true
end

function Generator:CompleteThirdPathRooms()
    for id = 1, #Generator.__Room_List do
        local Room = GetRoom(id)
        if #Room.Connectors <= 0 then
            continue
        end

        for _ = 1, #Room.Connectors do
            local Connector = Room.Connectors[1]
            if IsRoomOnCFrame(Connector.CFrame * CFrame.new(0, 0, -TILE_SIZE / 2)) then
                continue
            end

            local res = CreateRoom(
                GetRoomsWithConnectionCount(1) :: RoomTemplate, 
                Room.Id, 
                false
            )

            if res == false then
                print("Why did it fail? on room: ", id)
            end
        end
    end
end

function Generator:Generate(p_RoomId: number, list: { RoomTemplate }?, onlyfreedir: boolean?)
    task.wait(VIEW_TIME)
    if (Generator.__Room_Counter > Generator.__Max or p_RoomId + 1 > Generator.__Trail) then
        if p_RoomId + 1 > Generator.__Trail and Generator.__Infinite then
            Generator:CompleteThirdPathRooms()
        end

        return;
    end

    local LastRoom = GetRoom(p_RoomId)
    local ExcludeTags = {}
    if LastRoom and LastRoom.Tags then
        if table.find(LastRoom.Tags, "Hall") then
            ExcludeTags["Hall"] = true
        end
    end

    local Template = GetRoomWithMinConnections(2, list, ExcludeTags)
    local Created = CreateRoom(Template, p_RoomId, onlyfreedir)
    if Created == false then
        if onlyfreedir then
            RemoveLast()
            Generator:Generate(p_RoomId - 1, list, true)

            return;
        end

        local new_list = list or {}
        table.insert(new_list, Template)
        
        Generator:Generate(p_RoomId, new_list)

        return;
    elseif Created == nil and p_RoomId < Generator.__Max then
        if onlyfreedir then
            return;
        end

        RemoveLast()
        Generator:Generate(p_RoomId - 1, {}, true);

        return;
    end

    p_RoomId += 1;

    Generator:Generate(p_RoomId)
end

function Generator:Expand(At: number)
    local LastRoom = Generator.__Room_Counter

    if Generator.__Room_Count >= Generator.__Trail then
        local OldRoom = GetRoom(LastRoom - Generator.__Trail)
        RemoveRoom(OldRoom)
    end

    Generator:Generate(LastRoom)
end


return Generator