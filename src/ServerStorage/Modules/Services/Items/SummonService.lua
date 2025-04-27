--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--
local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Packages = Modules.Packages

local Banner = require(Packages.Summon.Banner)
local Network = require(Shared.Network)

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

end

-- ## Privates
--[[
    Handles the server event for the Service
]]
function Service.__ServerEvent(Player: Player, Request: {})
    print(Request)
end

return Service