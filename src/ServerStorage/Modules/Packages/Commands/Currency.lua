--
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules

local DataService = require(Modules.Services.Data.DataService)

--
return function(Caster: TextSource, Parameters: {})

    local CurrencyType = Parameters[1]
    local Amount = Parameters[2] or 0
    if not CurrencyType or (CurrencyType ~= 'Money' and CurrencyType ~= 'Gems') then
        return
    end

    --

    local Player = Players:GetPlayerByUserId(Caster.UserId)
    local PlayerCurrency = DataService:Get(Player, CurrencyType)

    DataService:Set(Player, CurrencyType, PlayerCurrency + Amount)
end
