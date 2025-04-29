--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Packages = Modules.Packages

local Places = require(Shared.Places)
local Banner = require(Packages.Summon.Banner)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local DataService = require(Modules.Services.Data.DataService)
local Probabilities = require(Shared.Database.Probabilities)
local PlayerAgentDataClass = require(Modules.Classes.Data.PlayerAgentData)

--
local Service = {}

function Service:Init()
    if Places:CanFight() then
        return
    end

    -- Load the banner
    Banner:Init()

    Network.new("Summon", "Event")
    Network:On("Summon", Service.__ServerEvent)

    --
    for _, Player in Players:GetPlayers() do
        Service:SyncBanner(Player)
    end
end

function Service:SyncBanner(Player: Player)
    if Places:CanFight() then
        return
    end

    Network:Fire("Banner", Player, 1, Banner:GetBanner())
end

function Service:SummonFromBanner()
    -- get character
    local Rarity = Probabilities:GetRollTypeFrom("Summon")
    local CharacterName = Banner:GetCharacterFromBannerWithRarity(Rarity)

    print("Pulled:", Rarity, CharacterName)
    -- replace later

    local ObtainedAgentDataClass = PlayerAgentDataClass.new(CharacterName, 1, DateTime.now().UnixTimestampMillis)

    return ObtainedAgentDataClass
end

-- ## Privates
--[[
    Handles the server event for the Service
]]
function Service.__ServerEvent(Player: Player, RequestType: number, BannerId: number)
    if RequestType == GameEnum.SummonRequests. SummonOne or RequestType == GameEnum.SummonRequests.SummonTen then
        local Amount = GameEnum.SummonRequests.SummonOne == RequestType and 1 or 10

        for idx = 1, Amount do
            local NewAgent = Service:SummonFromBanner()

            --print(NewAgent.Name, NewAgent)
            DataService:AddAgent(Player, NewAgent)
        end

        --
        -- print("Server summoned stuff :3")
    end
end

return Service