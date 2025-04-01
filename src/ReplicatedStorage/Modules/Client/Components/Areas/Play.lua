--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local PlayArea = {}

function PlayArea.OnEnter()
    local UIComponent = InterfaceController:GetComponent("Party")

    print("hey :3")
    UIComponent:Set(true)
end

function PlayArea.OnLeave()
    local UIComponent = InterfaceController:GetComponent("Party")

    UIComponent:Set(false)
end

return PlayArea