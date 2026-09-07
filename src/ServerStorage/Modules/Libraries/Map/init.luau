local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local settings = require(ServerStorage.Modules[".testenv"].settings)
local Types = require(Shared.Types.Stages)
local Cache = require(script.Parent.MapCache)
local Generator = require(script.new_generator)
local World = workspace:WaitForChild('World')

--
local MapLoader = {
    __Current_Loading_Data = {
        Infinite = false,
    },

    --- Layout the generator produced for this server, nil while the map is static.
    __Generation_Result = nil :: Types.MapGenerationResult?,
}

local function GetMap(p_MapPath: string): Folder?
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

function MapLoader:Unpack(p_MapPath: string, p_SpawnToUse: string?): boolean
    local SpawnId = p_SpawnToUse or 'SpawnLocation'
    local Map = GetMap(p_MapPath)
    if not Map then
        warn("MapLoader::Unpack - no map asset at path:", p_MapPath)

        return false
    end

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

function MapLoader:SetupMarkers(MarkerData: {[string]: Types.Marker}): {Destructibles: {}, Chests: {}, NPCS: {}}
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

    --- Was looking up '   Triggers', which never matched, so every call built a new folder.
    local Triggers = Map:FindFirstChild('Triggers') or Instance.new('Folder')
    Triggers.Name = 'Triggers'
    Triggers.Parent = Map

    for MarkerId, MarkerObj in (MarkerData or {}) do
        local ObjName = MarkerObj.Name or MarkerId

        if MarkerObj.Type == 'Trigger' then
            if MarkerObj.Data then
                MapLoader:SetupTrigger(Map, MarkerId, MarkerObj.Data, Triggers)
            else
                MapLoader:SetupTrigger(Map, MarkerId, ObjName, Triggers)
            end
        elseif MarkerObj.Type == 'Destructible' then
            local PartList = {}

            for _, Object in Map.Markers:GetChildren() do
                if Object.Name == MarkerId then
                    Object.Transparency = 1;
                    Object.CanQuery = false;
                    Object.CanCollide = false;
                    table.insert(PartList, Object)
                end
            end

            table.insert(MapData.Destructibles, {
                Id = MarkerId,
                Type = MarkerObj.Destructible_Id,
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
            if Part then
                table.insert(MapData.NPCS, Part)
            end
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

function MapLoader:SetupTrigger(Map: Folder & {Markers: Folder}, MarkerId: string, ObjNameOrData: string, Triggers: Folder)
    local Part = Map.Markers:FindFirstChild(MarkerId)
    if not Part then
        print(Part, 'not found!', MarkerId)

        return 
    end

    Part.CanQuery = false
    Part.CanCollide = false

    if typeof(ObjNameOrData) == 'table' then
        Part:AddTag('CustomObject')
        Cache:SaveTriggerData(MarkerId, ObjNameOrData)
    elseif typeof(ObjNameOrData) == 'string' then
        Part.Name = ObjNameOrData
    end

    Part.Parent = Triggers
    
    return Part
end


--
local function GetRoomsSource(p_MapFolder: Folder, p_Source: string): Folder?
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

--[[
    Procedurally build the map instead of unpacking a static one.

    @param p_MapPath Map asset the room source lives under.
    @param p_GenerationData Resolved generation parameters, see `Types.MapGenerationData`.

    @return The layout that was built, or nil when it could not be.
]]
function MapLoader:Generate(p_MapPath: string, p_GenerationData: Types.MapGenerationData): Types.MapGenerationResult?
    local MapFolder = GetMap(p_MapPath)
    if not MapFolder then
        warn("MapLoader::Generate - no map asset at path:", p_MapPath)

        return nil
    end

    MapLoader.__Current_Loading_Data.Infinite = p_GenerationData.Infinite == true
    MapLoader.__Generation_Result = nil

    --
    local Source = GetRoomsSource(MapFolder, p_GenerationData.Source)
    if not Source then
        warn("MapLoader::Generate - no room source:", p_GenerationData.Source, "under", p_MapPath)

        return nil
    end

    local Generated = Generator:Create(Source, p_GenerationData)
    Generated:Err(function(msg): ()
        warn("MapLoader::Generate - map generation errored: " .. msg)
    end)

    if Generated:IsErr() then
        return nil
    end

    MapLoader.__Generation_Result = Generated:Unwrap()

    return MapLoader.__Generation_Result;
end

--[[
    Turn every room the generator placed into a marker entry, so a generated dungeon goes
    through the exact same marker/trigger path a hand-built map does.

    Entries already declared by the mission win, that is how a mission attaches real event
    data (goals, enemies, dialogue) to a specific room.

    @param p_MarkerData Markers the mission declared, may be nil.

    @return A new merged marker table, the one passed in is left alone (it can belong to a
            cached stage act).
]]
function MapLoader:CreateMarkersForGeneratedMap(p_MarkerData: {[string]: Types.Marker}?): {[string]: Types.Marker}
    local Markers = table.clone(p_MarkerData or {})
    local Generated = MapLoader.__Generation_Result
    if not Generated then
        return Markers
    end

    for _, Room in Generated.Rooms do
        if Room.IsHall or not Room.Marker then
            continue
        end

        if Markers[Room.Marker.Name] then
            continue
        end

        Markers[Room.Marker.Name] = {
            Type = 'Trigger',
        } :: Types.Marker
    end

    return Markers
end

--- Layout the generator produced for this server, nil when the map is static.
function MapLoader:GetGenerationResult(): Types.MapGenerationResult?
    return MapLoader.__Generation_Result
end

function MapLoader:IsInfinite(): boolean
    return MapLoader.__Current_Loading_Data.Infinite
end

return MapLoader