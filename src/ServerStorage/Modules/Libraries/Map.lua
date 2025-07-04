local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

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
        SpawnObjectExists.Parent = workspace
    end

    for _, Object in NewMap:GetChildren() do
        if Object:IsA("Folder") then
            Object.Parent = World.Map
        end
    end

    return true
end

function MapLoader:SetupMarkers(MarkerData: {[string]: Types.Marker})
    local Map = World:WaitForChild("Map")
    if not Map:FindFirstChild('Markers') then
        return
    end

    for _, Part in Map.Markers:GetChildren() do
        Part:ClearAllChildren()
    end

    local Triggers = Map:FindFirstChild('Triggers') or Instance.new('Folder')
    Triggers.Name = 'Triggers'
    Triggers.Parent = Map

    for MarkerId, MarkerObj in MarkerData do
        local ObjName = MarkerObj.Name or MarkerId

        local Part = Map.Markers:FindFirstChild(MarkerId)
        if not Part then continue end

        Part.Name = ObjName

        if MarkerObj.Type == 'Trigger' then
            Part.Parent = Triggers
        end
    end
end

return MapLoader