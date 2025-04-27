--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local PlayArea = {
    Connection = nil,
}

function PlayArea.OnEnter(): ()
    local UIComponent = InterfaceController:GetComponent("Summon")

    UIComponent:Set(true)
end

function PlayArea.OnLeave()
    if PlayArea.Connection then
        PlayArea.Connection:Disconnect()
    end

    local UIComponent = InterfaceController:GetComponent("Summon")

    UIComponent:Set(false)
end

return PlayArea