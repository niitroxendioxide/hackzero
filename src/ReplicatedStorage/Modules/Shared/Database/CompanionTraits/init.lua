local TraitService = {
    __Cache = {},
    __Ids = {},
}

function TraitService:Init()

    for _, Trait in script:GetDescendants() do
        if Trait:IsA("ModuleScript") then
            local Success, Required = pcall(require, Trait)
            if Success then
                TraitService.__Cache[Trait.Name] = Required

                table.insert(TraitService.__Ids, Trait.Name)
            else
                warn(`Trait {Trait.Name} has an error: {Required}`)
            end

        end
    end
end

function TraitService:GetAllOfRarity(Rarity: string?)
    local List = {}

    if not Rarity then
        return TraitService.__Cache
    end

    for TraitName, TraitData in TraitService.__Cache do
        if TraitData.Rarity == Rarity then
            table.insert(List, TraitName)
        end
    end

    return List
end

function TraitService:GetIdFor(Name: string)
    return table.find(TraitService.__Ids, Name)
end

function TraitService:GetFromId(Id: number): string
    return TraitService.__Ids[Id]
end

return TraitService