local ServerStorage = game:GetService("ServerStorage")

local Classes = ServerStorage.Modules.Classes
local Libraries = ServerStorage.Modules.Libraries

local Agents = require(Libraries.Agents)
local ServerCompanion = require(Classes.Combat.ServerCompanion)

local Service = {}

function Service:Init()
    
end

function Service:CreateCompanion()
    local New = ServerCompanion.new("Default", {})
    local AgentList = Agents:GetActiveAgents()

    New:Init(1)
    New:Follow(AgentList[1])
    New:PivotTo(AgentList[1]:GetPivot())
end

return Service