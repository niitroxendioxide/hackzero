--
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services

local ArtifactsDatabase = require(ReplicatedStorage.Modules.Shared.Database.Artifacts)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local DataService = require(Services.Data.DataService)
local PlayerArtifactDataClass = require(Modules.Classes.Data.PlayerArtifactData)

--
return function(Caster: TextSource, Parameters: {[number]: string})
    local ItemName = Parameters[1]
    local Amount = tonumber(Parameters[2], 10)
    if not Amount then
        return
    end

    Amount = math.clamp(Amount, 1, 1024)

    local Level = math.clamp(Parameters[3] and tonumber(Parameters[3]) or math.random(5, 75), 1, 99)
    local ItemExists = ArtifactsDatabase:Get(ItemName);
    if not ItemExists then
        return;
    end

    --
    local Player = Players:GetPlayerByUserId(Caster.UserId)

    for i = 1, Amount do
        local NewArtifact = PlayerArtifactDataClass.randomize(ItemName, nil, Level)

        local Success, ErrMessage = DataService:AddArtifact(Player, NewArtifact)
        if not Success then
            Network:Fire("ServerError", Player, if typeof(ErrMessage) == 'string' then ErrMessage else `Cannot add artifact past 1024 limit.`)

            return
        end
    end

    --
    DataService:UpdatePlayerArtifacts(Player)
end
