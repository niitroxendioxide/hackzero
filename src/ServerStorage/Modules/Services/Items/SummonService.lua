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
local Statics = require(Shared.Database.Statics)
local Products = require(Shared.Database.Products)

local DataService = require(Modules.Services.Data.DataService)
local ShopService = require(Modules.Services.Lobby.ShopService)
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

        local GemRequirement = Amount * Statics.SummonCost
        local PlayerGems = DataService:Get(Player, "Gems")
        local HasEnough = PlayerGems >= GemRequirement
        if not HasEnough then
            local Difference = math.abs(PlayerGems - GemRequirement)
            local CurrentPass = 'Huge'

            for Key, Pass in Products.Dev_Products.Gems do
                if Pass.Amount <= Products.Dev_Products.Gems[CurrentPass].Amount and Pass.Amount >= Difference then
                    CurrentPass = Key
                end
            end

            print("broo buy this", Products.Dev_Products.Gems[CurrentPass])
            ShopService:PromptGemProduct(Player, CurrentPass)

            return
        end

        DataService:Set(Player, "Gems", PlayerGems - GemRequirement)

        local List = {};
        for idx = 1, Amount do
            local NewAgent = Service:SummonFromBanner()

            --print(NewAgent.Name, NewAgent)
            DataService:AddAgent(Player, NewAgent)

            table.insert(List, {NewAgent.Name})
        end

        Network:Fire("Summon", Player, GameEnum.SummonRequests.SummonResult, List)

        --
        -- print("Server summoned stuff :3")
    end
end

return Service