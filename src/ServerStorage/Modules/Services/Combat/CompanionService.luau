local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Classes = ServerStorage.Modules.Classes
local Libraries = ServerStorage.Modules.Libraries

local Companions = require(ReplicatedStorage.Modules.Shared.Types.Companions)
local Heap = require(ReplicatedStorage.Modules.Shared.Utility.Heap)
local Agents = require(Libraries.Agents)
local ServerCompanion = require(Classes.Combat.ServerCompanion)

local Service = {
    Count = nil :: Heap.Heap?,
    Classes = {} :: { Companions.CompanionClass },
}

function Service:Init()
    -- nun
    Service.Count = Heap.new(32)
end

function Service:CreateCompanion(CompanionDataClass: Companions.PlayerCompanionDataClass, Owner: number)
    if not CompanionDataClass or (Service.Count:isEmpty()) or not CompanionDataClass.GetStats then
        return;
    end

    local UUID = CompanionDataClass.__Id
    local New = ServerCompanion.new(CompanionDataClass.__Name, CompanionDataClass:GetStats(), UUID, CompanionDataClass.__Level)
    local AgentList = Agents:GetActiveAgents()

    local OwnerAgent = AgentList[1]

    New:Init(Service.Count:extract(), OwnerAgent)

    -- / follow the first agent for now
    New:Follow(OwnerAgent)
    New:PivotTo(OwnerAgent:GetPivot())

    table.insert(Service.Classes, New)
end

return Service