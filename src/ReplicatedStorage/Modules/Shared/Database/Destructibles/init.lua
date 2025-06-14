local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types.Structures)

--
local Destructibles = {
    __Cache = {},
    __Ids = {},
}

function Destructibles:Init()
    for _, Mod in script:GetChildren() do
        local Success, DataObtained = pcall(require, Mod)

        if Success then
            Destructibles.__Cache[Mod.Name] = DataObtained

            table.insert(Destructibles.__Ids, Mod.Name)
        else
            warn("Error loading data for: ", Mod.Name)
        end
    end
end

function Destructibles:GetData(Name: string): Types.DestructibleData?
    return Destructibles.__Cache[Name]
end

function Destructibles:GetId(Name: string)
    return table.find(Destructibles.__Ids, Name)
end

function Destructibles:FromId(Id: number)
    return Destructibles.__Ids[Id]
end

return Destructibles
