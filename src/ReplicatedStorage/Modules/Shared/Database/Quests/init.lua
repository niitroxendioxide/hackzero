local Quests = {
    Cache = {},
}

function Quests:Init()
    for _, Module in script:GetDescendants() do
        if not Module:IsA("ModuleScript") then continue end

        local Success, Required = pcall(require, Module)
        if Success then
            Quests.Cache[Module.Name] = Required
        else
            warn("Error loading quest: ", Module.Name)
        end
    end
end

function Quests:GetByName(Name: string)
    return Quests.Cache[Name]
end

return Quests
