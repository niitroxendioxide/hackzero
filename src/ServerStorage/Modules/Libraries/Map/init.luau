local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local settings = require(ServerStorage.Modules[".testenv"].settings)
local Types = require(Shared.Types.Stages)
local Generator = require(script.Generator)
local World = workspace:WaitForChild('World')

--
local MapLoader = {
    __Current_Loading_Data = {
        Infinite = false,
    }
}

function GetMap(p_MapPath: string): Folder?
    local Split = string.split(p_MapPath, "/")
    local Map = Assets:WaitForChild("Maps") :: Folder

    for i = 1, #Split do
        Map = Map:FindFirstChild(Split[i])

        if Map == nil then
            return nil
        end
    end

    return Map
end

function MapLoader:Unpack(p_MapPath: string, p_SpawnToUse: string?)
    local SpawnId = p_SpawnToUse or 'SpawnLocation'
    local Map = GetMap(p_MapPath)

    --
    local NewMap = Map:Clone()

    if NewMap:FindFirstChild('Lighting') then
        local Attributes = NewMap.Lighting:GetAttributes() :: {[string]: any}

        for Key, Val in Attributes do
            Lighting[Key] = Val
        end

        for _, Children: Instance in NewMap.Lighting:GetChildren() do
            local Parent = Lighting
            if Children:IsA("Clouds") then
                Parent = workspace:FindFirstChild("Terrain")
            end

            local Exists = Parent:FindFirstChildOfClass(Children.ClassName)
            if Exists then
                Exists:Destroy()
            end

            Children.Parent = Parent
        end

        NewMap.Lighting:Destroy()
    end

    if NewMap:FindFirstChild("Barriers") then
        local Barriers = NewMap.Barriers
        for _, BarrierObject in Barriers:GetChildren() do
            BarrierObject.CanCollide = false
            BarrierObject.CanQuery = true
        end

        Barriers.Parent = NewMap:FindFirstChild('Design')
    end

    -- [[  Set up in case you want to spawn in different places  ]]  --
    local SpawnObjectExists = NewMap:FindFirstChild(SpawnId, true)

    if SpawnObjectExists then
        for _, e_Spawn in workspace:GetChildren() do
            if e_Spawn:IsA("SpawnLocation") then
                e_Spawn:Destroy()
            end
        end

        SpawnObjectExists.Name = "SpawnLocation"
        SpawnObjectExists.CanCollide = false
        SpawnObjectExists.CanQuery = false
        SpawnObjectExists.Parent = workspace
    end

    for _, Object in NewMap:GetChildren() do
        if Object:IsA("Folder") then
            Object.Parent = World.Map
        end
    end

    return true
end

function MapLoader:SetupMarkers(MarkerData: {[string]: Types.Marker}): {Destructibles: {}, Chests: {}}?
    local MapData = {
        Destructibles = {},
        Chests = {},
        NPCS = {},
    }
    local Map = World:WaitForChild("Map")
    if not Map:FindFirstChild('Markers') then
        return MapData;
    end

    for _, Part in Map.Markers:GetChildren() do
        if RunService:IsStudio() and settings.REPLICATE_CONSTANTS.MARKERS then
            break
        end
        Part:ClearAllChildren()
    end

    local Triggers = Map:FindFirstChild( 'Triggers') or Instance.new('Folder')
    Triggers.Name = 'Triggers'
    Triggers.Parent = Map

    for MarkerId, MarkerObj in (MarkerData or {}) do
        local ObjName = MarkerObj.Name or MarkerId

        if MarkerObj.Type == 'Trigger' then
            MapLoader:SetupTrigger(Map, MarkerId, ObjName, Triggers)
        elseif MarkerObj.Type == 'Destructible' then
            local PartList = {}

            for _, Object in Map.Markers:GetChildren() do
                if Object.Name == MarkerId then
                    table.insert(PartList, Object)
                end
            end

            table.insert(MapData.Destructibles, {
                Id = MarkerObj.Destructible_Id,
                Parts = PartList,
            })
        elseif MarkerObj.Type == 'Chest' then
            local PartList = {}

            for _, Object in Map.Markers:GetChildren() do
                if Object.Name == MarkerId then
                    table.insert(PartList, Object)
                end
            end

            table.insert(MapData.Chests, {
                ItemList = MarkerObj.ItemList,
                Parts = PartList,
            })
        elseif MarkerObj.Type == 'NPC' then
            local Part = Map.Markers:FindFirstChild(MarkerId)
            table.insert(MapData.NPCS, Part)
        end
    end

    return MapData
end

function MapLoader:CreateTriggerFromData(Data: {Id: string, Name: string})
    local Map = World:WaitForChild("Map")
    local Triggers = Map:FindFirstChild("Triggers")
    if not Triggers then
        return
    end

    local Mission = MapLoader.__Mission_Object :: Types.MissionClass

    local TriggerPart = MapLoader:SetupTrigger(Map, Data.Id, Data.Name, Triggers)
    Mission:AddTrigger(TriggerPart)
end

function MapLoader:AssignCurrentMission(Mission)
    MapLoader.__Mission_Object = Mission
end

function MapLoader:SetupTrigger(Map: Folder & {Markers: Folder}, MarkerId: string, ObjName: string, Triggers: Folder)
    local Part = Map.Markers:FindFirstChild(MarkerId)
    if not Part then
        print(Part, 'not found!', MarkerId)
        return 
    end

    Part.CanQuery = false
    Part.CanCollide = false

    Part.Name = ObjName

    Part.Parent = Triggers

    return Part
end


--
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

function MapLoader:Generate(p_MapPath: string, p_GenerationData: Types.MapGenerationData): (boolean)
    local MapFolder = GetMap(p_MapPath)
    
    MapLoader.__Current_Loading_Data.Infinite = p_GenerationData.Infinite

    --
    local Source = GetRoomsSource(MapFolder, p_GenerationData.Source)

    local Result = Generator:Create(Source, p_GenerationData)
    Result:Err(function(msg): ()
        warn(msg)
    end)

    print('Generation result: ' .. Result)

    return Result();
end

function MapLoader:CreateMarkersForGeneratedMap()
    --local Rooms = World:FindFirstChild("Map"):FindFirstChild("Design")
end

function MapLoader:IsInfinite(): boolean
    return MapLoader.__Current_Loading_Data.Infinite
end

return MapLoader