--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared


local Companions = require(ReplicatedStorage.Modules.Shared.Types.Companions)
local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Statics = require(Shared.Database.Statics)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)

local DataService = require(Services.Data.DataService)
local AgentDatabase = require(Shared.Database.Characters)
local ItemDatabase = require(Shared.Database.Items)


--[[
    Handles giving rewards to the players
]]
local Service = {}

function Service:Init()
    Network.new("SellEvent", 'Event')
    Network:On("SellEvent", Service.__HandleEvent)
end

function Service.__HandleEvent(Player: Player, Type: number, ...)
    if Type == GameEnum.SellEvent.SellArtifacts then
        Service:SellArtifacts(Player, ...)
    end
end

function Service:SellArtifacts(Player: Player, List: { })
    local TierCount = {}
    DataService:ForEachArtifact(Player, function(Artifact: Types.PlayerArtifactDataClass): boolean  
        local ConvertedTier = GameEnum.Tiers[Artifact.__Tier]

        TierCount[ConvertedTier] = (TierCount[ConvertedTier] or 0) + 1;
    end)

    local Success = DataService:DeleteArtifacts(Player, List)
    if Success then
        Network:Fire("SellEvent", Player, GameEnum.SellEvent.SellArtifacts, List)
    end
end

return Service
