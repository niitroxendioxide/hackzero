--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)

---
local Notifications = {}

function Notifications:Init()
    Network.new("Notification", "Event")
end

function Notifications:Send(Player: Player, Type: number, Data: {any})
    Network:Fire("Notification", Player, Type, Data)
end

return Notifications
