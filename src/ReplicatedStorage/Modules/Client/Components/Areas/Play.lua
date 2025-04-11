--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local PlayArea = {
    Connection = nil,
}

function PlayArea.OnEnter()
    local UIComponent = InterfaceController:GetComponent("Interactions")

    UIComponent:SetButton("Create", true)
    UIComponent:SetButton("Join", true)

    PlayArea.Connection = UIComponent:WaitForClose(function()
        print("Do i not run?")
        PlayArea.OnEnter()
    end)
end

function PlayArea.OnLeave()
    if PlayArea.Connection then
        PlayArea.Connection:Disconnect()
    end

    local UIComponent = InterfaceController:GetComponent("Interactions")

    UIComponent:SetButton("Join", false)
    UIComponent:SetButton("Create", false)
end

return PlayArea