local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local settings = require(ServerStorage.Modules[".testenv"].settings)
local Types = require(Shared.Types.Stages)
local World = workspace:WaitForChild('World')

--
local MapLoader = {}

function MapLoader:Unpack(MapPath: string, SpawnToUse: string?)
    local Map = Assets:WaitForChild("Maps") :: Folder
    local Split = string.split(MapPath, "/")
    local SpawnId = SpawnToUse or 'SpawnLocation'

    for i = 1, #Split do
        Map = Map:FindFirstChild(Split[i])

        if Map == nil then
            return false
        end
    end

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
        SpawnObjectExists.Name = "MatchSpawnPlace"
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
    local Map = World:WaitForChild("Map")
    if not Map:FindFirstChild('Markers') then
        return
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

    local MapData = {
        Destructibles = {},
        Chests = {},
        NPCS = {},
    }

    for MarkerId, MarkerObj in MarkerData do
        local ObjName = MarkerObj.Name or MarkerId

        if MarkerObj.Type == 'Trigger' then
            local Part = Map.Markers:FindFirstChild(MarkerId)
            if not Part then continue end

            Part.CanQuery = false
            Part.CanCollide = false

            Part.Name = ObjName

            Part.Parent = Triggers
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

return MapLoader