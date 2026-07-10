local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local DataService = require(Services.Data.DataService)
local PlayerCompanionData = require(Classes.Data.PlayerCompanionData)

return function(Caster: TextSource, Params: {})

    local Type = Params[1] or 'Default'
    local Amount = tonumber(Params[2], 10) or 1
    local Player = Players:GetPlayerByUserId(Caster.UserId)

    for i = 1, Amount do
        local Class = PlayerCompanionData.randomize(Type)

        DataService:SaveCompanion(Player, Class)
    end
end
