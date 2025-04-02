local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local Places = require(Shared.Places)
local Network = require(Shared.Network)

local Controller = {
    __Current_Party = nil,
}

function Controller:Init()
    if not Places:IsInPlace("Lobby") then
        return;
    end

    Network:On("Party", function()
        
    end)
end

function Controller:JoinQueue(Party: Types.PartyClass)
    Controller.__Current_Party = Party;
end

return Controller
