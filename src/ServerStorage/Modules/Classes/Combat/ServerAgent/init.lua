--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

--
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local ArtifactsFetcher = require(ServerStorage.Modules.Libraries.ArtifactsFetcher)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local Types = require(Shared.Types.Agents)
local CharacterDatabase = require(Shared.Database.Characters)
local ServerGearClass = require(Classes.Combat.ServerAgent.ServerGear)
local MovementClass = require(Classes.Combat.ServerAgent.ServerMovement)
local AgentStatus = require(Shared.Classes.Agents.Status)
local AgentItems = require(Shared.Classes.Agents.Items)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local ServerAgentClass = {}
ServerAgentClass.__index = ServerAgentClass
ServerAgentClass.__tostring = function()
	return 'ServerAgentClass'
end


function ServerAgentClass.new(Name: string, Level: number): Types.ServerAgentClass
	local self = setmetatable({}, ServerAgentClass)
	self.Name = Name

	-- Privates
	local Appearance = CharacterDatabase:GetAppearanceData(Name)

	self.__Tags = {}
	self.__Level = Level
	self.__User = -125
	self.__Active = false
	self.__Last_Hit_Time = os.clock()
	self.__Last_Skill_Cast = os.clock()
	self.__Character = MovementClass.new(Name, Appearance.Height)
	self.__Status = AgentStatus.new(CharacterDatabase:GetStatsAtLevel(Name, Level))
	self.__Items = AgentItems.new(self)
	self.__Gear = ServerGearClass.new(self.__Items)

	return self
end

function ServerAgentClass:GetEnergy(): number
	return self.__Status:GetEnergy()
end

function ServerAgentClass:GetId(): number
	return self.__User
end

function ServerAgentClass:GetHitbox()
	return self.__Character.__Collider
end

function ServerAgentClass:GetTotalVelocity()
	return self.__Character:GetTotalVelocity()
end

function ServerAgentClass.Hit(self: Types.ServerAgentClass, Caster: Types.ServerAgentClass, Time: number)
	local AnimObject: Animation = ReplicatedStorage.Assets.Animations.General.Hit.AgentHit1;

	self.__Last_Hit_Time = os.clock()
	self:SwitchState('Stunned', Time)

	Replicator:HitAgent(self, Time, AnimObject)
end

function ServerAgentClass.IsBeingAttacked(self: Types.ServerAgentClass)
	return (os.clock() - self.__Last_Hit_Time) < 1.5 and (os.clock() - self.__Last_Skill_Cast) > 5
end

function ServerAgentClass.GetStat(self: Types.ServerAgentClass, Name: Types.Stat): number
	local Base = self.__Status:GetStat(Name)
	local Effects = self.__Status:GetStatEffects(Name)
	local ItemAdded = self.__Items:GetTotalAddedStat(Name)
	local GearAdded = self.__Gear:GetAddedGearStat(Name)

	local Total = Base + ItemAdded + GearAdded + Effects

	return Total
end

function ServerAgentClass.BindDrive(self: Types.ServerAgentClass, Drive: Types.Drive): ()
	self.__Items:BindDrive(Drive)
end

function ServerAgentClass.BindArtifact(self: Types.ServerAgentClass, Artifact: Types.Artifact): ()
	if not self.__Gear:HasObject(Artifact.Name) then
		local ObjectExtended = ArtifactsFetcher:ExtendFrom(Artifact.Name, Artifact.Level);

		self.__Gear:AddObject(ObjectExtended)
	end

	self.__Items:BindArtifact(Artifact)
end

function ServerAgentClass:GetMultBonus(Name: string)
	return self.__Status:GetMultBonus(Name)
end

function ServerAgentClass.GetUltimate(self: Types.ServerAgentClass): number
	return self.__Status:GetUltimate()
end


function ServerAgentClass.GiveUltimate(self: Types.ServerAgentClass, Amount: number): ()
	self.__Status:GiveUltimate(Amount)

	Replicator:UpdateUltBar(self.__Player_Assigned, self)
end

function ServerAgentClass.UseUltimate(self: Types.ServerAgentClass): ()
	self.__Status:UseUltimate({})

	Replicator:UpdateUltBar(self.__Player_Assigned, self)
end

function ServerAgentClass.Init(self: Types.ServerAgentClass, Player: Player)
	assert(typeof(Player:GetAttribute("ReplicationId")) == 'number', 'Cannot initialize character with nil key')

	self.__User = Player:GetAttribute("ReplicationId") :: number
	self.__Player_Assigned = Player

	--
	local ReplicationClock = os.clock()

	self.__Main_Thread = RunService.Heartbeat:Connect(function(Delta: number)
		self.__Status:Update(Delta)

		--
		if (os.clock() - ReplicationClock) > 1/(2.5) then
			ReplicationClock = os.clock()
			Replicator:UpdateCurrentEnergy(self.__Player_Assigned, self)
		end
	end)

	return self.__Character:Init()
end

function ServerAgentClass.SetActive(self: Types.ServerAgentClass, State: boolean)
	self.__Active = State
	Replicator:UpdateCurrentEnergy(self.__Player_Assigned, self)
end

function ServerAgentClass:IsMoving()
	return self.__Character:IsMoving()
end

function ServerAgentClass.Move(self: Types.ServerAgentClass)
	if not self.__Status:IsAlive() then
		self.__Character:Stop()

		return
	end

	return self.__Character:Move()
end

function ServerAgentClass:Stop()
	return self.__Character:Stop()
end

function ServerAgentClass:Rotate(...)
	if not self.__Status:IsAlive() then
		return
	end

	return self.__Character:Rotate(...)
end

function ServerAgentClass:GetCurrentSkill()
	return self.__Character.__States:GetCurrentSkill()
end

function ServerAgentClass:Look(...)
	return self:Rotate(...)
end

function ServerAgentClass.Walk(self: Types.ServerAgentClass, Time: number)
	local Speed = self.__Character.States:GetSpeed(true)
	local Direction = self:GetPivot().LookVector * Speed

	return self.__Character:AddLinearMovement(Direction, Time)
end

function ServerAgentClass:GetPivot(...)
	return self.__Character:GetPivot(...)
end

function ServerAgentClass:PivotTo(...)
	return self.__Character:PivotTo(...)
end

function ServerAgentClass:SetKey(...)
	return self.__Character.States:SetKey(...)
end

function ServerAgentClass:GetKey(...)
	return self.__Character.States:GetKey(...)
end

function ServerAgentClass:ApplyImpulse(Velocity: Vector3)
	return  self.__Character:ApplyImpulse(Velocity)
end

function ServerAgentClass:GetState()
	return self.__Character:GetState()
end

function ServerAgentClass:SwitchState(State: string, Time: number, Unaffected: boolean?)
	local Path = string.split(debug.info(2, "s"), '.')
	local Skill = Path[#Path]

	if State == 'Attacking' then
		self.__Character.States:SetCurrentSkill(Skill)
	elseif State ~= 'Attacking' and self.__Character.States:GetState() == 'Attacking' then
		self.__Character.States:SetCurrentSkill(nil)
	end

	local TimeMod = not Unaffected and State == 'Attacking' and self:GetStat("Speed") or 1

	self.__Character.States:Switch(State, Time / TimeMod)

	if self:IsMoving() then
		self:Move()
	end
end

function ServerAgentClass.MarkTarget(self: Types.ServerAgentClass, TargetId: number, Time: number): Types.AssistStruct?
	if self.__Current_Target then
		task.cancel(self.__Current_Target.Thread)
	end

	if TargetId == nil then
		self.__Current_Target = nil

		return
	end

	local Struct = {
		TargetId = TargetId,
		Accepted = Signal.new(),
		Time = Time,
	}

	self.__Current_Target = {
		Data = Struct,
		Thread = task.delay(Time, function()
			self.__Current_Target = nil
		end)
	}

	return (self.__Current_Target :: {Data: Types.AssistStruct, Thread: thread}).Data
end

function ServerAgentClass.GetMarkedTarget(self: Types.ServerAgentClass): Types.AssistStruct?
	if not self.__Current_Target then
		return nil
	end

	return self.__Current_Target.Data
end

-- # Interacting
function ServerAgentClass:TakeDamage(Amount: number)
	self.__Status:Damage(Amount)

	if not self.__Status:IsAlive() then
		Replicator:KillAgent(self, Amount);
	else
		Replicator:DamageAgent(self, Amount)
	end

	return
end

function ServerAgentClass:IsAlive()
	return self.__Status:IsAlive()
end

function ServerAgentClass:Heal(...)
	return self.__Status:Heal(...)
end

function ServerAgentClass:GetHealth(): (number, number)
	return self.__Status:GetHealth()
end

function ServerAgentClass:GiveEnergy(Amount: number): ()
	return self.__Status:GiveEnergy(Amount)
end

function ServerAgentClass:UseEnergy(Amount: number): ()
	self.__Status:UseEnergy(Amount)

	Replicator:UpdateCurrentEnergy(self.__Player_Assigned, self)
end

function ServerAgentClass:AddTag(Tag: string, Time: number)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil
	end)
end

function ServerAgentClass:RemoveTag(Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = nil
end

function ServerAgentClass:HasTag(Tag: string)
	return self.__Tags[Tag] ~= nil
end

function ServerAgentClass.AddEffect(self: Types.ServerAgentClass, EffectParams: Types.EffectParameters): Types.EffectObject
	EffectParams.Callback = function(Id: number)
		Replicator:RemoveEffect(self, Id)
	end

	local Effect = self.__Status:AddEffect(EffectParams)


	Replicator:AddEffect(self, EffectParams)

	return Effect
end

function ServerAgentClass.RemoveEffect(self: Types.ServerAgentClass, EffectId: number): Types.EffectObject
	local Effect = self.__Status:RemoveEffect(EffectId)

	Replicator:RemoveEffect(self, EffectId)

	return Effect
end

function ServerAgentClass.GetEffect(self: Types.ServerAgentClass, Tag: string): Types.EffectObject
	return self.__Status:GetEffect(Tag)
end

function ServerAgentClass.AddGear(self: Types.ServerAgentClass, GearName: string)
	local SuccessAdding = self.__Gear:AddGear(GearName)

	if SuccessAdding then
		Replicator:AddGear(self, GearName)
	end
end

function ServerAgentClass.RemoveGear(self: Types.ServerAgentClass, GearName: string)
	local SuccessRemoving = self.__Gear:AddGear(GearName)

	if SuccessRemoving then
		Replicator:RemoveGear(self, GearName)
	end
end

function ServerAgentClass.GetGearManager(self: Types.ServerAgentClass)
	return self.__Gear
end

return ServerAgentClass
