local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Services = Modules.Services

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local PartyService = require(Services.Lobby.PartyService)

local Service = {}

----
local function HandleEvent(Player: Player, Type: string, ...)
    local _Args = {...}

    if Type == 'CreateParty' then
        local PlayerParty = PartyService:CreateParty(Player)
        PlayerParty:SwitchStage("Expedition", "Training", "Intro")
        PlayerParty:SetData({Training = true})

        Network:Fire("Party", Player, GameEnum.PartyManaging.Create, PlayerParty:Compress(), PlayerParty:GetData())
    end
end

----
function Service:Init()
    Network.new("Training", "Event")

    Network:On("Training", HandleEvent)
end

return Service