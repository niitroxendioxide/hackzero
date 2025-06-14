--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Structures)

--
local List = {
    __Stored = {}
}

function List:Add(Structure: Types.DestructibleServerEntity)
    table.insert(List.__Stored, Structure)
end

function List:Remove(Structure: Types.DestructibleServerEntity)
    local index = table.find(List.__Stored, Structure)
    if index then
        table.remove(List.__Stored, index)
    end
end

function List:GetAll(): {Types.DestructibleServerEntity}
    return List.__Stored
end

function List:GetAllColliders()
    local Colliders = {}
    local Map = {}

    for _, Object in List.__Stored do
        local Collider = Object:GetCollider()
        table.insert(Colliders, Collider)

        Map[Collider] = Object
    end

    return Map, Colliders
end

return List