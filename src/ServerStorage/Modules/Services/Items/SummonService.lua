--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Packages = Modules.Packages

local Banner = require(Packages.Summon.Banner)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local Service = {}

function Service:Init()
    -- Load the banner
    Banner:Init()

    Network.new("Summon", "Event")
    Network:On("Summon", Service.__ServerEvent)
end

function Service:SyncBanner(Player: Player)
    Network:Fire("Banner", Player, Banner:GetBanner())
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