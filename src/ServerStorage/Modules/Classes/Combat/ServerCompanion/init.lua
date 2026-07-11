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
local Enemies = require(Shared.Libraries.Enemies)
local CompanionAttacks = require(ServerStorage.Modules.Libraries.CompanionAttacks)

---
local CompanionClass = {}
CompanionClass.__index = CompanionClass

function CompanionClass.new(Name: string, Stats: {}, UUID: string, Level: number)
    local self = setmetatable({}, CompanionClass)
    self.__Name = Name
    self.__UUID = UUID
    self.__Stats = StatsClass.new(Name, Stats, Level)
    self.__Movement = MovementClass.new(24)
    self.__Owner = nil
    self.__Thread = nil
    self.__Level = Level
    self.__Key = -1
    self.__Moving = false
    self.__State = 'Idle'
    self.__Last_Attack_Time = 0

    return self
end

function CompanionClass.Init(self: Types.CompanionClass, Key: number, Owner: AgentTypes.ServerAgentClass)
    assert(typeof(Key) == 'number', 'Invalid key id for companion class init.');

    self.__Movement:CreateCollider()

    self.__Key = Key
    self.__Owner = Owner
    Replicator:CreateCompanion(self)

    local Clock = os.clock()
    self.__Connection = RunService.Heartbeat:Connect(function(Delta: number)
        if self.__State == 'Idle' then
            self.__Movement:Update(Delta)
        end

        if self.__Moving ~= self.__Movement:IsMoving() then
            Replicator:SetMovingStatusCompanion(self, self.__Movement:IsMoving())
        end

        self.__Moving = self.__Movement:IsMoving()

        self:ComputeActions(Delta)

        if os.clock() - Clock > 1/6 then
            Clock = os.clock()
            Replicator:MoveCompanion(self, self.__Movement:GetPivot())
        end
    end)

end

function CompanionClass.SwitchState(self: Types.CompanionClass, State: string, Time: number)
    if self.__Thread then
        task.cancel(self.__Thread)
    end

    self.__State = State
    if State == 'Idle' then return end

    self.__Thread = task.delay(Time, function()
        self.__State = 'Idle'
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

function CompanionClass.GetStat(self: Types.CompanionClass, Stat: string): (number?)
    return self.__Stats:GetStat(Stat)
end

function CompanionClass.RemoveGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

function CompanionClass.AddGear(self: Types.CompanionClass, GearObject: AgentTypes.GearObject)

end

function CompanionClass.ComputeActions(self: Types.CompanionClass, Delta: number)
    if self.__State ~= 'Idle' then
        return
    end

    --
    self.__Last_Attack_Time += Delta

    local AttackRate = self:GetStat("AttackRate")

    if self.__Last_Attack_Time > AttackRate then
        self.__Last_Attack_Time = 0

        self:Attack()
    end
end

function CompanionClass.Attack(self: Types.CompanionClass)
    local _, Target = Enemies:GetNearestEnemy(self:GetPivot().Position, 70)
    local Attack = CompanionAttacks:GetAttack(self.__Name)
    if not Attack then
        return
    end

    Attack:Run(self, Target)
end

return CompanionClass
