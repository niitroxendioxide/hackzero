--
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Services = Modules.Services

local DataService = require(Services.Data.DataService)
local PlayerArtifactDataClass = require(Modules.Classes.Data.PlayerArtifactData)

--
return function(Caster: TextSource, Parameters: {[number]: string})
    local ItemName = Parameters[1]
    local Amount = tonumber(Parameters[2], 10)
    if not Amount then
        return
    end

    local Level = Parameters[3] and tonumber(Parameters[3]) or math.random(5, 75)

    --
    local Player = Players:GetPlayerByUserId(Caster.UserId)

    for i = 1, Amount do
        local NewArtifact = PlayerArtifactDataClass.randomize(ItemName, 'Epic', Level)

        DataService:AddArtifact(Player, NewArtifact)
    end

    --
    DataService:UpdatePlayerArtifacts(Player)
end
