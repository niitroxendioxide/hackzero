--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Characters = require(ReplicatedStorage.Modules.Client.Libraries.Characters)
local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
--local Enemies = require(Shared.Libraries.Enemies)
local CharacterClass = require(script:WaitForChild('Character'))
local StatusClass = require(Shared.Classes.Agents:WaitForChild('Status'))
local ItemsClass = require(Shared.Classes.Agents.Items)
local ClientGearClass = require(script:WaitForChild("ClientGear"))

--local InterfaceStates = require(Client.Packages.InterfaceStates)
local CharacterDatabase = require(Shared.Database.Characters)

--
local AgentClass = {} :: {[string]: (self: AgentTypes.AgentClass, any) -> any, new: (Name: string, Level: number) -> AgentTypes.AgentClass}
AgentClass.__index = AgentClass
AgentClass.__tostring = function(self)
	return `AgentClass<{self.Name}, {self.__Level}>`
end

function AgentClass.new(Name: string, Level: number, Skills: {}): AgentTypes.AgentClass
	local self = setmetatable({}, AgentClass)

	self.Name = Name
	self.PlayerId = -125

	-- # Private
	self:SetLevel(Level)
	self.__Tags = {}
	self.__Skill_Levels = Skills
	self.__Look_Marked = false
	self.__Skill_Thread = nil
	self.__Limit_Area = nil
	self.__Character = CharacterClass.new(Name)
	self.__Items = ItemsClass.new(self)
	self.__Gear = ClientGearClass.new()
	self.__Server_Action_Buffer = {};
	self.__Listener_Count = 0;

	return self
end

function AgentClass.IsActive(self : AgentTypes.AgentClass)
	local obtainedActiveAgent = Characters:GetCurrent(self.PlayerId)

	return (obtainedActiveAgent == self)
end

function AgentClass.GetAppearance(self: AgentTypes.AgentClass)
	return self.__Character.__Appearance
end

function AgentClass.IsAirborne(self: AgentTypes.AgentClass)
	return self:GetAppearance():GetAddedHeight() > 0
end

function AgentClass.Land(self: AgentTypes.AgentClass)
	return self:GetAppearance():Land()
end


function AgentClass.GetSkillLevel(self: AgentTypes.AgentClass, Name: string)
	return (self.__Skill_Levels[Name] or 1)
end

function AgentClass.SetPhysicsEnabled(self: AgentTypes.AgentClass, State: boolean)
	return self.__Character:SetPhysicsEnabled(State)
end

function AgentClass.MarkServerAction(self: AgentTypes.AgentClass, Type: number)
	if (self.__Listener_Count <= 0) then
		return;
	end

	if not table.find(self.__Server_Action_Buffer, Type) then
		table.insert(self.__Server_Action_Buffer, Type);
	end
end

function AgentClass.SetColliderGroupEnabled(self: AgentTypes.AgentClass, Group: {}, State: boolean)
	return self.__Character.__Controller:SetColliderGroupState(Group, State)
end

function AgentClass.GetId(self: AgentTypes.AgentClass): number
	return self.PlayerId
end

function AgentClass.SetLimitArea(self: AgentTypes.AgentClass, BasePart: BasePart)
	assert(typeof(BasePart) == 'Instance' or typeof(BasePart) == 'nil', "Invalid area given for the Agent\'s limit")

	self.__Limit_Area = BasePart
end

function AgentClass.GetLimitArea(self: AgentTypes.AgentClass)
	return self.__Limit_Area
end

function AgentClass:SetLevel(Amount: number)
	self.__Level = Amount
	self.__Status = StatusClass.new(CharacterDatabase:GetStatsAtLevel(self.Name, self.__Level))
end

function AgentClass:GetStat(Key: string)
	local Base = self.__Status:GetStat(Key) or 0
	local Effects = self.__Status:GetStatEffects(Key) or 0
	local Added = self.__Items:GetTotalAddedStat(Key) or 0
	local GearAdded = self.__Gear:GetAddedGearStat(Key) or 0

	local Total = Base + Added + Effects + GearAdded
	
	return Total
end

function AgentClass:SetMaxHealth(Amount: number, Fill: boolean)
	self.__Status:SetMaxHealth(Amount, Fill)
end

function AgentClass:GetAnimator(): Types.AnimatorController
	return self.__Character.__Animator
end

function AgentClass:GetHitbox(): BasePart
	return self.__Character.__Controller:GetCollider()
end

function AgentClass:AddTrackToState(...)
	return self:GetAnimator():AddTrackToState(...)
end

function AgentClass:Move()
	if not self.__Status:IsAlive() then
		return self:Stop()
	end

	return self.__Character:Move()
end

function AgentClass:Stop()
	return self.__Character:Stop()
end

function AgentClass:GetEnergy()
	return self.__Status:GetEnergy()
end

function AgentClass:Kill()
	self.__Status.__Alive = false
	self.__Locked = true

	task.delay(1, function()
		self.__Locked = false
	end)
end	

function AgentClass.SetEnemyCollisionState(self: AgentTypes.AgentClass, State: boolean)
	self.__Character.__Controller:SetEnemyCollisionState(State);
end

function AgentClass:CanSwitch(): boolean
	return not self.__Locked;
end

function AgentClass:IsAlive(): boolean
	return self.__Status:IsAlive()
end

function AgentClass:LookAtTarget(obj: any, not_instant: boolean)
	if obj == nil then
		return
	end

	local XZ = vector.create(1, 0, 1)
	local LookAt = CFrame.lookAt(self:GetPivot().Position * XZ, obj:GetPivot().Position * XZ).LookVector

	return self:Look(LookAt, not not_instant, true)
end

function AgentClass:Revive()
	self.__Status:Revive()
end

function AgentClass:SetEnergy(Amount: number)
	self.__Status:SetEnergy(Amount)
end

function AgentClass:ImpulseForward(Power: number, Time: number, Linear: boolean)
	return self.__Character.__Controller:ApplyForwardImpulse(Power, Time, Linear)
end

function AgentClass:BlockRotation(Time: number)
	if self.__Look_Marked_Thread then
		task.cancel(self.__Look_Marked_Thread)
	end

	self.__Look_Marked = true
	self.__Look_Marked_Thread = task.delay(Time, function()
		self.__Look_Marked = false
	end)
end

function AgentClass:Look(Vector, Instant, Bypass)
	local DashCheck = false --(self.__Character.__States:GetLastChangeTime() < .06) and self:GetState() ~= 'Dashing'
	if not Bypass and (self:GetState() == 'Attacking' or DashCheck) then --self.__Character.__States:Get
		return
	end

	if self.__Look_Marked then
		return
	end

	return self.__Character:Look(Vector, Instant)
end

function AgentClass:SetVisible(...)
	return self.__Character:SetVisible(...)
end

function AgentClass:CanBeHit()
	return (self:IsActive() or self:HasTag("CanBeTargetted"))
end

function AgentClass:Init(PlayerId: number)
	assert(typeof(PlayerId) == 'number', 'Requires a valid playerid to initialize agent.')

	self.PlayerId = PlayerId

	for _, Player in Players:GetPlayers() do
		if Player:GetAttribute("ReplicationId") == PlayerId then
			self.__Player_Assigned = Player
		end
	end

	self:SetMaxHealth(self:GetStat("Health"), true)

	--[[self.__Main_Thread = RunService.Heartbeat:Connect(function(Delta: number)
		self:Update(Delta)
	end)]]

	return self.__Character:Init()
end

function AgentClass.Update(self: AgentTypes.AgentClass, Delta: number)
	self.__Status:Update(Delta)
end

function AgentClass.CreateMeter(self: AgentTypes.AgentClass, Name: string, Data: {[string]: any})
	self.__Status:CreateMeter(Name, Data)
end

function AgentClass.UpdateMeter(self: AgentTypes.AgentClass, Meter: string, Amount: number)
	self.__Status:UpdateMeter(Meter, Amount)
end

function AgentClass.SetMeter(self: AgentTypes.AgentClass, Meter: string, Amount: number)
	self.__Status:SetMeter(Meter, Amount)
end

function AgentClass.GetAllMeters(self: AgentTypes.AgentClass)
	return self.__Status:GetAllMeters()
end

function AgentClass.SetMeterUpdateType(self: AgentTypes.AgentClass, Meter: string, Type: number, State: boolean, h): ()
	self.__Status:SetMeterUpdateType(Meter, Type, State, h)
end

function AgentClass.GetMeter(self: AgentTypes.AgentClass, Name: string): (number, number)
	for _, Meter in self.__Status:GetAllMeters() do
		if Meter.Name == Name then
			return Meter.Value, Meter.Value / Meter.Max
		end
	end

	return 0, 0
end

function AgentClass:GetRotation(): any
	return self.__Character.__Controller.__Rotation
end

function AgentClass:SyncVelocities(LM, SV, MV, V)
	local Character = self.__Character;
	local Controller = Character.__Controller;

	Controller.__Velocity = LM or Controller.__Velocity
	Controller.__SurfaceVelocity = SV or Controller.__SurfaceVelocity
	Controller.__MovementVelocity = MV or Controller.__MovementVelocity
	Controller.__LastMovementVelocity = V or Controller.__LastMovementVelocity
end

function AgentClass:GetPivot(Server: boolean)
	if Server and self.__ServerLocation then
		return self.__ServerLocation
	end

	return self.__Character:GetPivot()
end

function AgentClass:GetKey(...)
	return self.__Character:GetKey(...)
end

function AgentClass:SetHealth(Amount)
	return self.__Status:SetHealth(Amount)
end

function AgentClass:SetKey(...)
	return self.__Character:SetKey(...)
end

function AgentClass:GetModel()
	return self.__Character:GetModel()
end

function AgentClass:IsMoving()
	return self.__Character:IsMoving()
end

function AgentClass:Walk(Time: number, Mod: number?, Linear: boolean?)
	Mod = Mod or 1
	local Speed = self.__Character.__States:GetSpeed(true)

	if self.__current_walking_object then
		self.__Character.__Controller:RemoveForwardImpulse(self.__current_walking_object)
	end

	if Time <= 0 then
		return
	end

	local Object = self:ImpulseForward(Speed * 1.5 * Mod, Time, Linear)
	self.__current_walking_object = Object

	return Object--self.__Character.__Controller:AddLinearMovement(Direction, Time)
end

function AgentClass:WalkBack(Time: number, Mod: number?, Linear: boolean)
	Mod = Mod or 1

	if self.__current_walking_object then
		self.__Character.__Controller:RemoveForwardImpulse(self.__current_walking_object)
	end

	if Time <= 0 then
		return
	end

	local Speed = self.__Character.__States:GetSpeed(true)

	local Object = self:ImpulseForward(Speed * -1 * Mod, Time, Linear)
	self.__current_walking_object = Object

	return Object
end

function AgentClass:PivotTo(...)
	return self.__Character:PivotTo(...)
end

function AgentClass:ApplyImpulse(...)
	return self.__Character.__Controller:ApplyImpulse(...)
end

function AgentClass:AddEffect(...)
	return self.__Status:AddEffect(...)
end

function AgentClass:ChangeEffect(...)
	return self.__Status:ChangeEffect(...)
end

function AgentClass:GetEffect(...)
	return self.__Status:GetEffect(...)
end

function AgentClass.AwaitServerTriggeredAction(self: AgentTypes.AgentClass, Type: number)
	self.__Listener_Count += 1;
	
	if table.find(self.__Server_Action_Buffer, Type) then
		self.__Listener_Count -= 1;
	else
		repeat
			task.wait()
		until table.find(self.__Server_Action_Buffer, Type);

		self.__Listener_Count -= 1;
	end

	if (self.__Listener_Count <= 0) then
		self.__Listener_Count = 0;
		table.clear(self.__Server_Action_Buffer);
	end
end

function AgentClass:RemoveEffect(...)
	return self.__Status:RemoveEffect(...)
end

function AgentClass:GetState()
	return self.__Character:GetState()
end

function AgentClass:SetUltBar(Amount: number)
	return self.__Status:SetUltimate(Amount)
end

function AgentClass:GetUltBar()
	return self.__Status:GetUltimate()
end

function AgentClass:SwitchState(State: string, Time: number, Iframes: boolean?, Unaffected: boolean?): ()
	local TimeMod = not Unaffected and State == 'Attacking' and self:GetStat("Speed") or 1
	local TakenTime = Time / TimeMod

	self.__Character.__States:Switch(State, TakenTime)
	if self.__c_recovery_thread then
		task.cancel(self.__c_recovery_thread)
	end

	if Iframes then
		self:AddTag('Invulnerability', TakenTime)
	end

	self.__c_recovery_thread = task.delay(TakenTime, function()
		self._c_recovery_thread = nil

		if self:IsMoving() then
			self:Move()
		end
	end)

	if self:IsMoving() then
		self:Move()
	end
end

function AgentClass:SetCurrentSkill(Skill: string, Time: number?)
	Time = Time or 9e12

	return self.__Character.__States:SetCurrentSkill(Skill, Time)
end

function AgentClass:GetCurrentSkill(): string
	return self.__Character.__States:GetCurrentSkill()
end

-- # Gameplay Core
function AgentClass:IsDead()
	return self.__Status.Health > 0
end

function AgentClass:TakeDamage(...)
	return self.__Status:Damage(...)
end

function AgentClass:Heal(...)
	return self.__Status:Heal(...)
end

function AgentClass:GetHealth(): (number, number)
	return self.__Status:GetHealth()
end

function AgentClass:AddTag(Tag: string, Time: number)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	local Hitbox = self:GetHitbox()
	Hitbox:AddTag(Tag)

	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil
		Hitbox:RemoveTag(Tag)
	end)
end

function AgentClass:RemoveTag(Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	local Hitbox = self:GetHitbox()
	Hitbox:RemoveTag(Tag)

	self.__Tags[Tag] = nil
end

function AgentClass:HasTag(Tag: string)
	return self.__Tags[Tag] ~= nil
end

return AgentClass
