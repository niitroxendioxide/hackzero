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
    print(Type, Request)

    if Type == GameEnum.AgentEvent.UpdateArtifactSlot then
        Service:SetAgentArtifactSlot(Player, Request[1], Request[2])
    end
end

function Service:SetAgentArtifactSlot(Player: Player, AgentName: string, ArtifactId: string)
    local Artifact = DataService:GetArtifacts(Player, function(Artifact)
        return Artifact.__Id == ArtifactId
    end) :: Types.PlayerArtifactDataClass

    local Agent = DataService:GetAgent(Player, AgentName)

    local UnequippedAgent, ReplacedSlot = Artifact:EquipTo(Agent)
    warn("ADD REPLACED SLOT FUNCTIONALITY !! :(")
    print(Artifact.__Id)

    --
    local Compressed = Artifact:Compress()
    if UnequippedAgent ~= Agent then
        Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateArtifactSlot, {
            GameEnum.ArtifactEvent.Add, Compressed, Agent.Name
        })
    end

    if UnequippedAgent then
        Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateArtifactSlot, {
            GameEnum.ArtifactEvent.Remove, Compressed, UnequippedAgent.Name,
        })
    end

    if ReplacedSlot then
        warn("YOU MUST SHOW THE REPLACED SLOT ")
    end
end

function Service:SetAgentWeapon(Player: Player, Agent: string, Weapon: string)
    return Types.NOT_IMPLEMENTED_ERROR()
end


return Service
