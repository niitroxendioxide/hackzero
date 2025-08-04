--
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService('Players')

local Modules = ServerStorage.Modules
local Services = Modules.Services

local DataService = require(Services.Data.DataService)
local PlayerArtifactDataClass = require(Modules.Classes.Data.PlayerArtifactData)

--
return function(Caster: TextSource, Parameters: {[number]: string})
    local Amount = tonumber(Parameters[1], 10)
    if not Amount then
        return
    end

    local Level = Parameters[2] and tonumber(Parameters[2]) or math.random(5, 75)

    --
    local Player = Players:GetPlayerByUserId(Caster.UserId)

    for i = 1, Amount do
        local NewArtifact = PlayerArtifactDataClass.randomize('Wristband', 'Epic', Level)

        DataService:AddArtifact(Player, NewArtifact)
    end

    --
    DataService:UpdatePlayerArtifacts(Player)
end
