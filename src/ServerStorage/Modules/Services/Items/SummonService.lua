--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Packages = Modules.Packages

local Banner = require(Packages.Summon.Banner)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Places = require(Shared.Places)

local Notifications = require(Modules.Packages.Notifications)

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
    local FullCharacters = Banner:GetBanner()

    -- replace later
    return FullCharacters[math.random(1, #FullCharacters)][1]
end

-- ## Privates
--[[
    Handles the server event for the Service
]]
function Service.__ServerEvent(Player: Player, RequestType: number, BannerId: number)
    if RequestType == GameEnum.SummonRequests.SummonOne then
        print("have to summon in banner: ", BannerId)

        local Obtained = Service:SummonFromBanner()
        print("obtained:", Obtained)

        Notifications:Send(Player, GameEnum.NotificationTypes.ObtainedCharacter, {Obtained})
    elseif RequestType == GameEnum.SummonRequests.SummonTen then
        print("have to summon in banner: ", BannerId)

        local List = {}
        for i = 1, 10 do
            table.insert(List, Service:SummonFromBanner())
        end

        print("Obtained:", List)
    end
end

return Service