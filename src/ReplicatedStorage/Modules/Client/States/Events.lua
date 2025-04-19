--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Fusion = require(Client.Libraries.Fusion)
local Types = require(Shared.Types)
local Peek = Fusion.peek

--
local Events = {
    __States = {},
}

function Events:New(Name: string, Values: {[Types.Stage_Objective]: any})
    if Events.__States[Name] ~= nil then
        return
    end

    Events.__States[Name] = Fusion.scoped({Value = Fusion.Value})

    --
    local Scope = Events.__States[Name]
    local Returned = {}

    for ValueKey, ValueType in Values do
        local InitialValue = typeof(ValueType) == "number" and 0 or false
        if ValueKey == "AllReachPlace" then
            InitialValue = 0
        end

        Scope[ValueKey] = Scope:Value(InitialValue)
        Returned[ValueKey] = Scope[ValueKey]
    end

    return Returned
end

function Events:Set(Name: string, Key: string, Value: any)
    local Scope = Events.__States[Name]
    if not Scope then
        return
    end

    Scope[Key]:set(Value)
end

function Events:Get<T>(Name: string, Key: string, Raw: boolean): T?
    local Scope = Events.__States[Name]
    if not Scope then
        return
    end

    if Raw then
        return Scope[Key]
    else
        return Peek(Scope[Key])
    end
end

function Events:Delete(Name: string)
    Events.__States[Name] = nil
end

return Events