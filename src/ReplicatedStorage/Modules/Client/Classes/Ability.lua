	--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local AnimLibrary = require(Client.Libraries.Animation)

local Effects = require(Client.Libraries.Effects)

local Types = require(Shared.Types.Abilities)
local AgentTypes = require(Shared.Types.Agents)
local DefaultTypes = require(Shared.Types)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Shared.Utility.Hitbox)
local Enemies = require(Shared.Libraries.Enemies)
local Sequence = require(Shared.Utility.Sequence)
local CharactersLib = require(Client.Libraries.Characters)
--local CharacterDatabase = require(Shared.Database.Characters)

local Cooldown = require(Shared.Utility.Cooldown)
local GameEnum = require(Shared.GameEnum)
local Replicator = require(Client.Libraries.Replicator)

--
local AbilityClass = {} :: {[string]: (self: Types.AbilityClass, any) -> any, new: () -> Types.AbilityClass}
AbilityClass.__index = AbilityClass

function AbilityClass.new(Holdable: boolean): Types.AbilityClass
	local Dir = string.split(debug.info(2, 's'), '.')

	local self = setmetatable({}, AbilityClass)
	self.__Character = Dir[#Dir - 1]
	self.__Name = Dir[#Dir]:gsub(' ', '_')
	self.Name = self.__Name

	self.__Active_Sequences = {}
	self.__Cache = {}
	self.__Holdable = Holdable
	self.__Signal = Signal.new()
	self.__Cooldown = Signal.new()
	self.__Ability_Data = {}

	self.__Held = {}

	return self
end

function AbilityClass:Begin(Agent: AgentTypes.AgentClass, Frames: Sequence.SequenceFrames, DontPlay: boolean?): Types.Sequence
	if self.__Active_Sequences[Agent] then
		self.__Active_Sequences[Agent]:Destroy()
	end

	--
	local AbilitySequence = Sequence.new(Frames, self.__Name)
	local Attack_Warnings = self:FromData('Attack_Warning')
	local Agent_Speed_Mod = Agent:GetStat("Speed")

	if typeof(Attack_Warnings) ~= 'nil' and Attack_Warnings > 0 then
		local function PlayWarningEffect()
			Effects:Play('Warning', Agent)
		end

		local Ping = Replicator:GetPing()
		if typeof(Attack_Warnings) == 'table' then
			for _, Time in Attack_Warnings do
				AbilitySequence:Add(math.max(Time - Ping, 0), PlayWarningEffect)
			end
		else
			AbilitySequence:Add(math.max(Attack_Warnings - Ping, 0), PlayWarningEffect)
		end
	end

	local Base_Speed = (self:FromData('Speed') or 1)
	AbilitySequence:SetSpeed( Base_Speed * Agent_Speed_Mod)
	AbilitySequence:After(function()
		self:Save(Agent, "CurrentSkillSavedObjects", nil)
		self.__Signal:Fire()
	end)

	self:Save(Agent, 'CurrentPlayerSequence', AbilitySequence)

	self.__Active_Sequences[Agent] = AbilitySequence

	if not DontPlay then
		AbilitySequence:Start()
	end

	return AbilitySequence
end

function AbilityClass:Connect(Agent: AgentTypes.AgentClass, StateId: number)
	local User = Players.LocalPlayer
	local Id = User:GetAttribute("ReplicationId")

	if Id == Agent.PlayerId then
		local LookAtEnemy = self:FromData('NoAutoTrack') ~= true
		local EnemyId, Enemy;
		if LookAtEnemy then
			EnemyId, Enemy = Enemies:GetNearestEnemy(Agent:GetPivot().Position, 15, true)
		end

		if Enemy and (self.__Name ~= 'Dodge') then
			Agent:Look(CFrame.lookAt(Agent:GetPivot().Position * Vector3.new(1, 0, 1), Enemy:GetPivot().Position * Vector3.new(1, 0 ,1)).LookVector, false, true)
		end

		Replicator:Replicate(GameEnum.Replication.PivotTo, Agent:GetPivot(), true)
		Replicator:Replicate(GameEnum.Replication.UseSkill, GameEnum.Skills[self.__Name], EnemyId, StateId)
	end
end

function AbilityClass:Effect(Name: string, ...)
	return Effects:Play(Name, ...)
end

function AbilityClass:FromData(Key: string, Sub_Key: number, GivenLevel: number?): ()
	if Key == 'Knockback' then
		return {self:FromData('Knockback_Direction'), self:FromData('Knockback_Strength'), self:FromData('Knockback_Time')}
	end

	local Base = self.__Ability_Data.Base
	local Upgrade = self.__Ability_Data.Upgrades or {}

	local Level = math.max((GivenLevel or 1) - 1, 0)
	local Value = Base[Key] or 0
	local Upgraded_Value = Upgrade[Key]

	if typeof(Value) == 'table' and Sub_Key ~= nil then
		local Added = Upgraded_Value ~= nil and Upgrade[Key][Sub_Key]

		if Added then
			return Value[Sub_Key] + Added * Level
		else
			return Value[Sub_Key]
		end
	end

	if Key == "Speed" and Value == nil then
		Value = 1
	end

	return Value
end

function AbilityClass:SetData(Data: {})
	self.__Ability_Data = Data
end

function AbilityClass:SetCooldown(Agent: AgentTypes.AgentClass, Time: number)
	local ID = self.__Character..self.__Name..Agent.PlayerId

	Cooldown:Add(ID, Time)
end

function AbilityClass:Play(Agent: AgentTypes.AgentClass)
	print(Agent.Name, 'Ability executed!')

	self:Begin(Agent, {})
end

function AbilityClass:IsHeld(Caster: Types.Caster)
	return self.__Held[Caster]
end

function AbilityClass:PlayAnimation(Agent: AgentTypes.AgentClass, Track: string, Data: DefaultTypes.AnimationDataOptions)
	Data = Data or {}

	local Agent_Speed_Mod = Agent:GetStat("Speed")
	Data.Speed = (Data.Speed or 1) * (self:FromData('Animation_Speed') or 1) * Agent_Speed_Mod

	local AnimCache = self:Get(Agent, "CurrentSkillSavedObjects")
	if AnimCache == nil then
		self:Save(Agent, "CurrentSkillSavedObjects", {})
		AnimCache = self:Get(Agent, "CurrentSkillSavedObjects")
	end

	--
	local Model = Data.Model or Agent:GetModel()
	local Type = tostring(Agent) == 'AgentClass' and 'Characters.' or 'Enemies.'
	local TrackObject = AnimLibrary:GetAnim(Type..Track)
	local AnimTrack = AnimLibrary:Play(Model, TrackObject, Data.Fade or 0, Data.Weight or 1, Data.Speed or 1)
	AnimTrack.Priority = Enum.AnimationPriority.Action2 or Data.Priority

	if tostring(Agent) == 'AgentClass' then
		Agent:AddTrackToState('Attacking', AnimTrack, Data.Active_Time or 0.35)
	end

	table.insert(AnimCache, AnimTrack)

	return AnimTrack
end

--
function AbilityClass:CreateHitbox(Caster: Types.Caster, Offset, Size, Event)
	if tostring(Caster) == 'EnemyClass' then
		return self:CreateAgentHitbox(Caster, Offset, Size, Event)
	elseif tostring(Caster) == 'AgentClass' then
		return self:CreateEnemyHitbox(Caster, Offset, Size, Event)
	end

	return;
end

function AbilityClass:CreateAgentHitbox(Enemy: Types.Caster, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.Target) -> ())
	Hitbox:ForAgentsInZone(CharactersLib, Size, Enemy:GetPivot() * CFrame.new(Offset), function(Agent, ...)
		if Agent:HasTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER) then
			Agent:RemoveTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)

			if Agent.PlayerId == Players.LocalPlayer:GetAttribute("ReplicationId") then
				return
			end
		end

		Event(Agent, ...)
	end)
end


function AbilityClass:CreateEnemyHitbox(Agent: Types.Caster, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.Target) -> ())
	local World = workspace:FindFirstChild('World') :: Folder

	local EnemyHitboxes = Enemies:GetHitboxes()
	local AreaParts = Hitbox:GetPartsInArea({World.Entities.Hitboxes}, Size, Agent:GetPivot() * CFrame.new(Offset))

	for _, Part in  AreaParts do
		local Enemy = EnemyHitboxes[Part]
		if not Enemy then
			continue
		end

		--
		task.spawn(Event, Enemy)
	end
end

function AbilityClass:Save(Agent: AgentTypes.AgentClass, Key: string, Value: any)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end

	self.__Cache[Agent][Key] = Value
end

function AbilityClass:Get(Agent: AgentTypes.AgentClass, Key: string)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end

	return self.__Cache[Agent][Key]
end

function AbilityClass:Increase(Agent: AgentTypes.AgentClass, Key: string, Data: {Rate: number?, Limit: number?})
	Data = Data or {}

	local Limit = Data.Limit or math.huge
	local Added = Data.Rate or 1
	local CurrentValue = self:Get(Agent, Key) or 0

	if CurrentValue + Added > Limit then
		self:Save(Agent, Key, 1)
	else
		self:Save(Agent, Key, CurrentValue + Added)
	end
end

function AbilityClass.UseAttackData(self: Types.AbilityClass, Sequence: Types.Sequence, Caster: Types.Caster, Data: {[number]: number}, Hitbox_Data: Types.HitboxAttackData)

	--
	local Walk_Event_Time = Data[GameEnum.AttackData.Movement_Time]

	if Walk_Event_Time and Walk_Event_Time > 0 then
		local Movement_Length = Data[GameEnum.AttackData.Movement_Length]
		local Movement_Strength = Data[GameEnum.AttackData.Movement_Strength]

		Sequence:Add(Walk_Event_Time, function()
			local Length = (typeof(Movement_Length) == 'number' and math.abs(Movement_Length) > 0 and Movement_Length) or self:FromData("Walk_Time") or 0.15
			local Power = (typeof(Movement_Strength) == 'number' and Movement_Strength > 0 and Movement_Strength) or 1

			local Direction = math.sign(Length)
			local TimeToWalk = math.abs(Length)

			if Direction == -1 then
				Caster:WalkBack(TimeToWalk, Power)
			else
				Caster:Walk(TimeToWalk, Power)
			end
		end)
	end

	local End_Lag = Data[GameEnum.AttackData.End_Lag]
	if End_Lag and End_Lag > 0 then
		Caster:SwitchState("Attacking", End_Lag)
	end

	--
	local Hit_Event_Time = Data[GameEnum.AttackData.Hit_Time]

	if Hit_Event_Time and Hit_Event_Time > 0 and Hitbox_Data then
		Sequence:Add(Hit_Event_Time, function()
			self:CreateHitbox(Caster, Hitbox_Data.Offset, Hitbox_Data.Size, Hitbox_Data.Hit_Function)
		end)
	end
end

function AbilityClass.Cancel(self: Types.AbilityClass, Agent: any, Context: {Hit: boolean?})
	Context = Context or {}

	-- destroy after u  clear anims, else the value resets to nil hehe
	local Sequence = self:Get(Agent, "CurrentPlayerSequence")
	if Sequence then
		Sequence:Destroy()
	end

	if not Context.Hit then
		Agent:SwitchState("Idle", 0)
	end

	self:Save(Agent, "CurrentSkillSavedObjects", nil)
end

return AbilityClass
