local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Player = Players.LocalPlayer

local Types = require(Shared.Types)
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local InterfaceController = require(ReplicatedStorage.Modules.Client.Controllers.InterfaceController)


--
local Controller = {
    __Current_Party = nil,
}

function Controller:Init()
    if not Places:IsInPlace("Lobby") then
        return;
    end

    Network:On("Party", function(Type: number, PartyData): ()
        local PartyComponent = InterfaceController:GetComponent("Party")

        if Type == GameEnum.PartyManaging.Create then
            PartyComponent:Set(true)
            PartyComponent:AddPlayerToList(Player.DisplayName)
        elseif Type == GameEnum.PartyManaging.Leave then
            PartyComponent:Set(false)
        elseif Type == GameEnum.PartyManaging.Failed then
            PartyComponent:SetButtonState("Play", true)
        end
    end)
end

function Controller:JoinQueue(Party: Types.PartyClass)
    Controller.__Current_Party = Party;
end

return Controller
