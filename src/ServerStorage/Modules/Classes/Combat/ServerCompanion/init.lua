--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")


local Shared = ReplicatedStorage.Modules.Shared

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local Types = require(Shared.Types.Companions)
local AgentTypes = require(Shared.Types.Agents)
local MovementClass = require(script.Movement)
local StatsClass = require(script.Stats)

---
local CompanionClass = {}
CompanionClass.__index = CompanionClass

function CompanionClass.new(Name: string, Level: number)
    local self = setmetatable({}, CompanionClass)
    self.__Stats = StatsClass.new(Name, Level)
    self.__Movement = MovementClass.new(self.__Stats:GetStat("Speed"))
    self.__Owner = nil
    self.__Level = Level
    self.__Gear = {}
    self.__Key = -1

    return self
end

function CompanionClass.Init(self: Types.CompanionClass, Key: number)
    self.__Movement:CreateCollider()

    self.__Key = Key
    Replicator:CreateCompanion(self)

    local Clock = os.clock()
    self.__Connection = RunService.Heartbeat:Connect(function(Delta: number)
        self.__Movement:Update(Delta)

        if os.clock() - Clock > 1/6 then
            Clock = os.clock()
            Replicator:MoveCompanion(self, self.__Movement:GetPivot())
        end
    end)

end

function CompanionClass.PivotTo(self: Types.CompanionClass, At: CFrame)
    return self.__Movement:PivotTo(At)
end

function CompanionClass.GetPivot(self: Types.CompanionClass)
    return self.__Movement:GetPivot()
end

function CompanionClass.Follow(self: Types.CompanionClass, Agent: AgentTypes.ServerAgentClass)
    self.__Movement:Follow(Agent)
end


function CompanionClass.RemoveGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

function CompanionClass.AddGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

return CompanionClass
