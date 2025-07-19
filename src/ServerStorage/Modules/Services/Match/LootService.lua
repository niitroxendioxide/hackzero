local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Signal = require(Shared.Utility.Signal)

--
local Service = {
    OnLootboxOpened = nil :: Signal.ScriptSignal<Player, {Items: {[string]: {}}}>?;
}

function Service:Init()
    Service.OnLootboxOpened = Signal.new()
end

function Service:SetupChests(Chest_Data: {})
    -- do somethng here
end

return Service