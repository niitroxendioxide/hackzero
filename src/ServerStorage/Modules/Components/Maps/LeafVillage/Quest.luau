--[[
    Server component for LeafVillage/Quest.

    Placeholder, no hooks attached yet. It still returns a StageClass so `StageHandlers`
    picks it up as a valid component rather than skipping it.
]]

local ServerStorage = game:GetService("ServerStorage")

local StageClass = require(ServerStorage.Modules.Classes.Game.Stage)

return StageClass.new()
