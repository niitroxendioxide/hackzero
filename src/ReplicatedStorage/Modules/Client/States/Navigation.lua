local States = {
    Movement_Locked = false,
}

local Stores = {}

local Module = {}

type keys = 'Movement_Locked' | 'CanInteract' | string
function Module:Get(Key: keys)
    return States[Key]
end

function Module:Set(Key: keys, Value: boolean)
    if Value == true and States[Key] == true then
        Stores[Key] = (Stores[Key] or 0) + 1
    elseif Value == false then
        Stores[Key] = math.max((Stores[Key] or 0) - 1, 0)
    end

    States[Key] = if Stores[Key] == 0 then Value else true
end

return Module