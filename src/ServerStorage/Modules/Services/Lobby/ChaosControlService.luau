---
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)

---
local Service = {}

function HandleEvent(Player: Player, Type: number)
        
end

function Service:Init()

    Network.new("ChaosControl", 'Event')
    Network:On("ChaosControl", HandleEvent)

end

return Service