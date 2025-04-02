--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local PlayArea = {}

function PlayArea.OnEnter()
    local UIComponent = InterfaceController:GetComponent("Interactions")

    UIComponent:SetButton("Play", true)
end

function PlayArea.OnLeave()
    local UIComponent = InterfaceController:GetComponent("Interactions")

    UIComponent:SetButton("Play", false)
end

return PlayArea