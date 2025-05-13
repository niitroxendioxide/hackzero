--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)

local DataService = require(Services.Data.DataService)

--[[
    Handles setting up the builds & using the data from the player artifacts & more
]]
local Service = {}

function Service:Init()
    Network.new("UpdateAgent", 'Event')
    Network:On("UpdateAgent", Service.__HandleEvent)
end

function Service.__HandleEvent(Player: Player, Type: number, Request: {})
    if Type == GameEnum.AgentEvent.UpdateArtifactSlot then
        Service:SetAgentArtifactSlot(Player, Request[1], Request[2], Request[3])
    end
end

function Service:SetAgentArtifactSlot(Player: Player, Agent: string, Slot: number, ArtifactId: string)
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:SetAgentWeapon(Player: Player, Agent: string, Weapon: string)
    return Types.NOT_IMPLEMENTED_ERROR()
end


return Service
