--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

--
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local ArtifactsFetcher = require(ServerStorage.Modules.Libraries.ArtifactsFetcher)
local Movesets = require(ServerStorage.Modules.Libraries.Movesets)
local Ping = require(ServerStorage.Modules.Libraries.Ping)
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


function ServerAgentClass.new(Name: string, Level: number, Skills: {}, Ascensions: number): Types.ServerAgentClass
	Skills = Skills or {}

	local self = setmetatable({}, ServerAgentClass)
	self.Name = Name

	-- Privates
	local Appearance = CharacterDatabase:GetAppearanceData(Name)
	if Skills and not table.isfrozen(Skills) then
		table.freeze(Skills :: {})
	end

	self.__Tags = {}
	self.__Level = Level
	self.__User = -125
	self.__Active = false
	self.__Ascension = Ascensions
	self.__Skill_Levels = Skills
	self.__Meter_updates = {}
	self.__Last_Hit_Time = os.clock()
	self.__Last_Skill_Cast = os.clock()
	self.__Character = MovementClass.new(Name, Appearance.Height)
	self.__Status = AgentStatus.new(CharacterDatabase:GetStatsAtLevel(Name, Level))
	self.__Items = AgentItems.new(self)
	self.__Gear = ServerGearClass.new(self.__Items)

	return self
end

function ServerAgentClass.GetAscension(self: Types.ServerAgentClass)
	return self.__Ascension;
end

function ServerAgentClass.SetColliderGroupEnabled(self: Types.ServerAgentClass, Group: {}, State: boolean)
	return self.__Character:SetColliderGroupState(Group, State)
end

function ServerAgentClass.GetSkillLevel(self: Types.ServerAgentClass, SkillName: string)
	return (self.__Skill_Levels[SkillName] or 0)
end

function ServerAgentClass.SetLimitArea(self: Types.ServerAgentClass, BasePart: BasePart)
	assert(typeof(BasePart) == 'Instance'or typeof(BasePart) == 'nil', "Invalid area given for the Agent\'s limit")

	self.__Limit_Area = BasePart
end

function ServerAgentClass.GetLimitArea(self: Types.ServerAgentClass)
	return self.__Limit_Area
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

function ServerAgentClass:ImpulseForward(Power: number, Time: number)
	return self.__Character:ApplyForwardImpulse(Power, Time)
end

function ServerAgentClass.Hit(self: Types.ServerAgentClass, Caster: Types.Enemy, Time: number)
	local Ping = Ping:Get(self.__Player_Assigned)
	local CurrentSkill = self:GetCurrentSkill()
	if CurrentSkill then
		local Moveset = Movesets:Get(self.Name)

		Moveset:CancelSkill(CurrentSkill, self, {ClientInstruction = true})
	end

	self.__Last_Hit_Caster = Caster:GetId()
	self.__Last_Hit_Time = os.clock()

	task.delay(Ping / 2, self.SwitchState, self, "Stunned", Time)

	Replicator:HitAgent(self, Time)
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

	self:SetMaxHealth(self:GetStat("Health"), true)

	self.__Main_Thread = RunService.Heartbeat:Connect(function(Delta: number)
		self.__Status:Update(Delta)

		--
		if (os.clock() - ReplicationClock) > 1/(2.5) then
			ReplicationClock = os.clock()
			Replicator:UpdateCurrentEnergy(self.__Player_Assigned, self)
		end

		for _, MeterData in self.__Status:GetAllMeters() do
			if (os.clock() - MeterData.LastUpdate >= 1) and (MeterData.Fill or MeterData.Empty) then
				local Change = MeterData.Fill and MeterData.FillSpeed or MeterData.Empty and -MeterData.EmptySpeed
				local Previous = MeterData.Value

				MeterData.LastUpdate = os.clock()
				MeterData.Value = math.clamp(MeterData.Value + Change, 0, MeterData.Max)

				if Previous ~= MeterData.Value then
					local hasEmptied = (Previous > MeterData.Value and MeterData.Value <= 0)
					if hasEmptied and MeterData.EmptiedHandler then
						task.spawn(MeterData.EmptiedHandler)
					elseif (Previous < MeterData.Value and MeterData.Value == MeterData.Max) and MeterData.FilledHandler then
						task.spawn(MeterData.FilledHandler)
					end
				end

				local Percent = MeterData.Value / MeterData.Max
				Replicator:UpdateMeter(self, MeterData.Id, MeterData.Value, Percent)
			end
		end
	end)

	return self.__Character:Init()
end

function ServerAgentClass.UpdateMeter(self: Types.ServerAgentClass, Meter: string, Amount: number)
	if not self.__Status:HasMeter(Meter) then
		return;
	end

	
	local MeterObject = self.__Status:UpdateMeter(Meter, Amount)
	local Percent = MeterObject.Value / MeterObject.Max

	for _, MeterEvent in self.__Meter_updates do
		if MeterEvent.Meter == Meter then
			MeterEvent.Handle(MeterObject.Id, MeterObject.Value, Percent)
		end
	end

	Replicator:UpdateMeter(self, MeterObject.Id, MeterObject.Value, Percent)
end

function ServerAgentClass.OnMeterUpdated(self: Types.ServerAgentClass, Meter: string, fn: (Id: number, Value: number, Percent: number) -> ())
	table.insert(self.__Meter_updates, {
		Meter = Meter,
		Handle = fn,
	})
end

function ServerAgentClass.GetAllMeters(self: Types.ServerAgentClass)
	return self.__Status:GetAllMeters()
end

function ServerAgentClass.SetMeterUpdateType(self: Types.ServerAgentClass, Meter: string, Type: number, State: boolean, h): ()
	self.__Status:SetMeterUpdateType(Meter, Type, State, h)
end

function ServerAgentClass.CreateMeter(self: Types.ServerAgentClass, Name: string, Data: {[string]: any})
	self.__Status:CreateMeter(Name, Data)
	
	Replicator:CreateMeter(self, Name, Data)
end

function ServerAgentClass.GetMeter(self: Types.ServerAgentClass, Name: string): (number, number)
	for _, Meter in self.__Status:GetAllMeters() do
		if Meter.Name == Name then
			return Meter.Value, Meter.Value / Meter.Max
		end
	end

	return 0, 0
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
	return self.__Character.States:GetCurrentSkill()
end

function ServerAgentClass:Look(...)
	return self:Rotate(...)
end

function ServerAgentClass:LookAtTarget(obj: any)
	if obj == nil then
		return
	end

	local XZ = vector.create(1, 0, 1)
	local LookAt = CFrame.lookAt(self:GetPivot().Position * XZ, obj:GetPivot().Position * XZ).LookVector

	return self:Look(LookAt, true, true)
end

function ServerAgentClass.Walk(self: Types.ServerAgentClass, Time: number, Mod: number?)
	Mod = Mod or 1
	local Speed = self.__Character.States:GetSpeed(true)

	if self.__current_walking_object then
		self.__Character:RemoveForwardImpulse(self.__current_walking_object)
	end

	local Object = self:ImpulseForward(Speed * 1.5 * Mod, Time)
	self.__current_walking_object = Object

	return Object--self.__Character.__Controller:AddLinearMovement(Direction, Time)
end

function ServerAgentClass.WalkBack(self: Types.ServerAgentClass, Time: number, Mod: number?)
	Mod = Mod or 1

	if self.__current_walking_object then
		self.__Character:RemoveForwardImpulse(self.__current_walking_object)
	end

	local Speed = self.__Character.States:GetSpeed(true)

	local Object = self:ImpulseForward(Speed * -1 * Mod, Time)
	self.__current_walking_object = Object

	return Object
end

function ServerAgentClass:GetPivot(...)
	return self.__Character:GetPivot(...)
end

function ServerAgentClass.PivotTo(self: Types.ServerAgentClass, Place: CFrame, replicator_inside_call: boolean)
	self.__Character:PivotTo(Place)

	if not(replicator_inside_call) then
		Replicator:PivotTo(self.__Player_Assigned, Place)

		-- second call because it excludes the player
		Replicator:PivotTo(self.__Player_Assigned, Place, self.__Player_Assigned)
	end
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

function ServerAgentClass:SwitchState(State: string, Time: number, Iframes: boolean?, Unaffected: boolean)
	--local TimeExtra = Ping:Get(self.__Player_Assigned)
	local TimeMod = not Unaffected and State == 'Attacking' and self:GetStat("Speed") or 1
	
	self.__Character.States:Switch(State, (Time) / TimeMod)
	if Iframes then
		self:AddTag('Invulnerability', Time / TimeMod)
	end

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

		self:Stop()
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

function ServerAgentClass:SetMaxHealth(Amount: number, Fill: boolean)
	self.__Status:SetMaxHealth(Amount, Fill)
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

function ServerAgentClass:AddTag(Tag: string, Time: number?, Replicate: boolean?)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil

		Replicator:RemoveTag(self, Tag)
	end)

	--
	if Replicate then
		Replicator:AddTag(self, Tag, Time)
	end
end

function ServerAgentClass:RemoveTag(Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = nil

	Replicator:RemoveTag(self, Tag)
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
