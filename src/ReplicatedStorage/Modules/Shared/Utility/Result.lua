--!strict
--[[
    @niitroxendioxide 2025-10
    Standarized for most of my projects

    @class ResultClass
    A result from a function, either Ok or Err,
    Inspired by rust, but not exactly the same functionality, as roblox has no Enum Type
]]


--
local ResultClass = {}
ResultClass.__index = ResultClass
ResultClass.__newindex = function<T, E>(self: Result<T, E>, key: string, value: any)
    return error("Result is immutable")
end
ResultClass.__eq = function<T, E>(self: Result<T, E>, Val: boolean)
    if (Val == true and self:IsOk()) or (Val == false and self:IsErr()) then
        return true 
    end

    return false
end

ResultClass.__call = function<T, E>(self: Result<T, E>)
    return self:IsOk()
end

ResultClass.__concat = function<T, E>(Previous: string, self: Result<T, E>)
    if self:IsOk() then
        return Previous .. tostring(self.__TypePair[1])
    end

    return Previous .. tostring(self.__TypePair[2])
end


-- Creating
ResultClass.new = function<T, E>(OkValue: T?, ErrorValue: E?): Result<T, E>
    local self = {
        __TypePair = {OkValue, ErrorValue} :: {T? | E?},
    }

    return setmetatable(self, ResultClass) :: Result<T, E>
end

-- Class methods
function ResultClass.Ok<T, E>(self: Result<T, E>, fn: (OkValue: T) -> ()): Result<T, E>
    if self.__TypePair[1] then
        task.spawn(fn, self.__TypePair[1] :: T)
    end

    return self :: Result<T, E>
end

function ResultClass.Err<T, E>(self: Result<T, E>, fn: (ErrValue: E) -> ()): Result<T, E>
    if self.__TypePair[2] then
        task.spawn(fn, self.__TypePair[2] :: E)
    end

    return self :: Result<T, E>
end

function ResultClass.IsOk<T, E>(self: Result<T, E>): boolean
    return self.__TypePair[1] ~= nil
end

function ResultClass.IsErr<T, E>(self: Result<T, E>): boolean
    return self.__TypePair[2] ~= nil
end

--export type IterResult<T, E> = {Value: T | E, Type: "Ok" | "Err"}

export type Result<T, E> = typeof(setmetatable({}, ResultClass)) & {
    __TypePair: {T | E},

    Ok: (self: Result<T, E>, fn: (OkValue: T) -> ()) -> Result<T, E>,
    Err: (self: Result<T, E>, fn: (ErrValue: E) -> ()) -> Result<T, E>,
    
    IsOk: (self: Result<T, E>) -> (boolean),
    IsErr: (self: Result<T, E>) -> (boolean),
}

return ResultClass