--
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

local ItemDatabase = require(Shared.Database.Items)
local DataService = require(Modules.Services.Data.DataService)
local PlayerItemDataClass = require(Modules.Classes.Data.PlayerItemData)

--
return function(Caster: TextSource, Parameters: {})

    local ItemName = Parameters[1]
    if not ItemName then
        return
    end

    local Amount = tonumber(Parameters[2] or 0, 10)

    --
    if not ItemDatabase:Verify(ItemName) then
        return
    end

    local Player = Players:GetPlayerByUserId(Caster.UserId)
    local RandomDrive = PlayerItemDataClass.new(ItemName, Amount)

    DataService:SaveItem(Player, RandomDrive)
    DataService:UpdatePlayerItems(Player)
end
