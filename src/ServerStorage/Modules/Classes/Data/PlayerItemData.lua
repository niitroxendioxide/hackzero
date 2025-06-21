local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local ItemDatabase = require(Shared.Database.Items)
local ItemDataTypes = require(Shared.Types.Data)

--
local PlayerItemDataClass = {}
PlayerItemDataClass.__index = PlayerItemDataClass

function PlayerItemDataClass.new(Type: string, Amount: number)
    local self = setmetatable({}, PlayerItemDataClass)
    self.__Name = Type
    self.__Amount = Amount

    return self
end

function PlayerItemDataClass.SetAmount(self: ItemDataTypes.PlayerItemDataClass, NewAmount: number)
    local Data = ItemDatabase:GetItemData(self.__Name) or {Max = math.huge}

    self.__Amount = math.clamp(NewAmount, 0, Data.Max)
end

function PlayerItemDataClass.ToData(self: ItemDataTypes.PlayerItemDataClass)
    return {
        Name = self.__Name,
        Amount = self.__Amount,
    }
end

function PlayerItemDataClass.Compress(self: ItemDataTypes.PlayerItemDataClass): (buffer, string?)
    local Id = ItemDatabase:GetIdFor(self.__Name) or 0
    local BufferObj = buffer.create(6)
    buffer.writeu16(BufferObj, 0, Id)
    buffer.writef32(BufferObj, 2, self.__Amount)

    if Id == 0 then
        local BufferSize = 6 + #self.__Name
        local New = buffer.create(BufferSize)
        buffer.writeu16(New, 0, Id)
        buffer.writef32(New, 2, self.__Amount)
        buffer.writestring(New, 6, self.__Name)

        BufferObj = New
    end

    return BufferObj
end

return PlayerItemDataClass