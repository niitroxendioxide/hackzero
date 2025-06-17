local Interface = {
    __States = {},
}

function Interface:Set(Key: string, Value: any)
    Interface.__States[Key] = Value
end

function Interface:Get<T>(Key: string): T?
    return Interface.__States[Key]
end

return Interface