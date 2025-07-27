--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local Shared = ReplicatedStorage.Modules.Shared
local Classes = Shared.Classes.Companion

local Types = require(Shared.Types.Companions)
local AgentTypes = require(Shared.Types.Agents)
local MovementClass = require(Classes.Movement)
local StatsClass = require(Classes.Stats)

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

    self.__Connection = RunService.Heartbeat:Connect(function(Delta: number)
        self.__Movement:Update(Delta)
    end)

end

function CompanionClass.Follow(self: Types.CompanionClass, Agent: AgentTypes.ServerAgentClass)
    self.__Movement:Follow(Agent)
end


function CompanionClass.RemoveGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

function CompanionClass.AddGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

return CompanionClass
