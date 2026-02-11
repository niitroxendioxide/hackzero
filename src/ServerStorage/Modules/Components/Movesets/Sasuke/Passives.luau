---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)

---
local PassiveManager = {}

function PassiveManager:OnPassiveFilled(Id: number, Caster: Types.ServerAgentClass)
    --- do stuff here
end

return PassiveManager
