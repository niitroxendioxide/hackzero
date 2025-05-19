--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local Controller = {
    __Reward_Data = {},
}

function Controller:Init()
    Network:On("AFKEvent", function(Type: number, Payload: {})
        if Type == GameEnum.AFKEvent.GiveCurrency then
            Controller:UpdateCurrency(Payload[1], Payload[2])
        end
    end)
end

function Controller:UpdateCurrency(Type: string, Amount: number)
    local Element = InterfaceController:GetComponent("AFK")

    if not Controller.__Reward_Data[Type] then
        Controller.__Reward_Data[Type] = 0
    end

    Controller.__Reward_Data[Type] += Amount
    Element:ShowCurrency(Type, Controller.__Reward_Data[Type])
end

return Controller