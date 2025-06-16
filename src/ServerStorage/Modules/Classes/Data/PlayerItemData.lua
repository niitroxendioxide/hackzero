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
    local Data = ItemDatabase:GetItemData(self.__Name)

    self.__Amount = math.clamp(NewAmount, 0, Data.Max)
end

function PlayerItemDataClass.ToData(self: ItemDataTypes.PlayerItemDataClass)
    return {
        Name = self.__Name,
        Amount = self.__Amount,
    }
end

function PlayerItemDataClass.Compress(self: ItemDataTypes.PlayerItemDataClass): buffer
    local Id = ItemDatabase:GetIdFor(self.__Name)
    local BufferObj = buffer.create(6)
    buffer.writeu16(BufferObj, 0, Id)
    buffer.writef32(BufferObj, 2, self.__Amount)

    return BufferObj
end

return PlayerItemDataClass