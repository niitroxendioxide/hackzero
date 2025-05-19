--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local DataService = require(Modules.Services.Data.DataService)

--
local Service = {
    __Player_Clock = 0,
}

function Service:Init()
    if not Places:IsInPlace("AFK") then
        return
    end

    --
    RunService.Heartbeat:Connect(function(Delta: number)

    end)
end

function Service:GiveCurrency(Player: Player, Type: 'Gems' | 'Money', Amount: number)
    local PlayerCurrencyVal = DataService:Get(Player, Type)
    if PlayerCurrencyVal == nil then
        return
    end

    DataService:Set(Player, PlayerCurrencyVal + Amount)
end

return Service
