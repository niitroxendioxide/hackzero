--!strict
--[[
    @niitroxendioxide 2025-10

    @service WorkersService

    Generates quests using NPC interactions from the client, with a few parameters
    such as 'QuestType', to determine whether if it's a deal damage or recover item quest.
    
    Generates also a value for how much reputation the quest gives
]]

type QuestType = "DealDamage" | "RecoverItem"

--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)

local Service = {}


-- Private
function InteractionEvent()
    
end

-- Püblic
function Service:GenerateQuestFromSeed(p_Seed: string, p_Type: QuestType)
    local CuratedSeed = tonumber(p_Seed, 16) :: number
end

function Service:Init()
    Network.new("Workers", "Event")
    Network:On("Workers", InteractionEvent)
end

return Service
