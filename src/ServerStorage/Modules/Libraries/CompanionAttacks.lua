local ServerStorage = game:GetService("ServerStorage")

local Components = ServerStorage.Modules.Components

local List = {
    __Cache = {}
}

function List:Init()

    for _, Folder in Components.Companions:GetChildren() do
        local MainDirName = Folder.Name

        List.__Cache[MainDirName] = {}
        for _, Module in Folder:GetChildren() do
            local Success, Required = pcall(require, Module)
            if Success then
                List.__Cache[MainDirName][Module.Name] = Required
            else
                warn('Error loading companion module: ', Required)
            end
        end
    end

end

function List:GetPassive(Name: string)
    return List.__Cache[Name] and List.__Cache[Name].Passive
end

function List:GetAttack(Name: string)
    return List.__Cache[Name] and List.__Cache[Name].Attack
end

return List