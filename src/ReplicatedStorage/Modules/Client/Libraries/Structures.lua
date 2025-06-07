local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Components = Client.Components

--
local Structures = {
    __Handlers = {},
}

function Structures:Init()
    for _, Structure in Components.Destructibles:GetChildren() do
        local Success, HandlerObj = pcall(require, Structure)

        if Success then
            Structures.__Handlers[Structure.Name] = HandlerObj
        end
    end
end

function Structures.Create(Type: string, Data)
    if not Structures.__Handlers[Type] then
        return
    end

    local Handler = Structures.__Handlers[Type]
    Handler:Create(Data)
end

function Structures.Destroy(Type: string, Data)
    if not Structures.__Handlers[Type] then
        return
    end

    local Handler = Structures.__Handlers[Type]
    Handler:Destroy(Data)
end

return Structures