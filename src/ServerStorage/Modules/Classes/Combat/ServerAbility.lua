--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Enemies = require(Shared.Libraries.Enemies)

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Shared.Utility.Hitbox)
local Sequence = require(Shared.Utility.Sequence)
local GameEnum = require(Shared.GameEnum)

local ServerHitboxUtil = require(ServerStorage.Modules.Libraries.Hitbox)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local DamageLibrary = require(ServerStorage.Modules.Libraries.Damage)
local AgentsLibrary = require(ServerStorage.Modules.Libraries.Agents)
local WorldCamera = workspace:WaitForChild('Camera')

--
local ServerAbilityClass = {} :: {[string]: (self: Types.ServerAbilityClass, any) -> any, new: () -> Types.ServerAbilityClass}
ServerAbilityClass.__index = ServerAbilityClass

function ServerAbilityClass.new(): Types.ServerAbilityClass
	local Path = debug.info(2, "s")
	local Split = string.split(Path, '.')

	local self = setmetatable({}, ServerAbilityClass)
	self.__Cache = {}
	self.__Name = string.gsub(string.gsub(Split[#Split], ' Server', ''), ' ', '_')
	self.__Cooldown = Signal.new()
	self.__Signal = Signal.new()
	self.__Hit = Signal.new()
	self.__Ability_Data = {}
	self.__Held = {}

	return self
end

function ServerAbilityClass:Play(Agent: AgentTypes.ServerAgentClass)
	print(Agent.Name, 'Ability executed!')

	self:Begin(Agent, {})
end

function ServerAbilityClass:CreateHitbox(Caster: AgentTypes.ServerAgentClass & Types.ServerEnemyClass, Offset, Size, Event)
	local At = Caster:GetPivot()
	ServerHitboxUtil:ForStructuresInZone(Size,  At * CFrame.new(Offset), function(Structure)
		Event(Structure)
	end)

	--
	if tostring(Caster) == 'EnemyClass' then
		return self:CreateAgentHitbox(Caster, Offset, Size, Event)
	elseif tostring(Caster) == 'ServerAgentClass' then
		return self:CreateEnemyHitbox(Caster, Offset, Size, Event)
	end

	return;
end

function ServerAbilityClass:CreateEnemyHitbox(Agent: AgentTypes.ServerAgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.ServerEnemyClass) -> ())
	local EnemyHitboxes = Enemies:GetHitboxes()
	local AreaParts = Hitbox:GetPartsInArea({WorldCamera.Enemies}, Size, Agent:GetPivot() * CFrame.new(Offset))

	for _, Part in  AreaParts do
		local Enemy = EnemyHitboxes[Part]

		task.spawn(Event, Enemy)
	end
end

function ServerAbilityClass:CreateAgentHitbox(Enemy: Types.ServerEnemyClass, Offset: Vector3, Size: Vector3, Event: (Enemy: AgentTypes.ServerAgentClass) -> ())
	ServerHitboxUtil:ForAgentsInZone(Size, Enemy:GetPivot() * CFrame.new(Offset), function(Target: AgentTypes.ServerAgentClass, ...)
		if Target:HasTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER) then
			print(Target.Name, 'DODGED')
			Target:RemoveTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)

			return
		end

		Event(Target, ...)
	end)
end

function ServerAbilityClass:Save(Agent: AgentTypes.AgentClass, Key: string, Value: any)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end

	self.__Cache[Agent][Key] = Value
end

function ServerAbilityClass:Increase(Agent: AgentTypes.ServerAgentClass, Key: string, Data: {Rate: number?, Limit: number?})
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

function ServerAbilityClass:Get(Agent: AgentTypes.AgentClass, Key: string)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end

	return self.__Cache[Agent][Key]
end

function ServerAbilityClass:Begin(Agent: AgentTypes.ServerAgentClass, Frames: Sequence.SequenceFrames): Types.Sequence
	local Sequence_Speed = self:FromData('Speed') or 1
	local Agent_Speed = Agent:GetStat("Speed")

	local AbilitySequence = Sequence.new(Frames)
	AbilitySequence:SetSpeed(Sequence_Speed * Agent_Speed)

	AbilitySequence:After(function()
		self.__Signal:Fire()
	end)

	return AbilitySequence:Start()
end


-- Hit functions
local function HitEnemy(Agent: AgentTypes.ServerAgentClass, Enemy: Types.ServerEnemyClass, Data: Types.HitEnemyData)
	local AgentPivot = Agent:GetPivot()
	local _EnemyPivot = Enemy:GetPivot()


	--
	local Dealt_Damage, EnemyDied, Critical, Affliction, Affliction_Fill, Burst_Damage, Affliction_Triggered = DamageLibrary:Deal(Agent, Enemy, Data)
	local Dealt_Daze, Is_Dazed = DamageLibrary:Daze(Agent, Enemy, Data.Daze)

	--
	local EnergyAmount = (Dealt_Damage / Enemy.__Status:GetStat("Max_Health")) / 1.25
	if not Data.DontChargeEnergy then
		Agent:GiveEnergy(EnergyAmount)
	end

	if not Data.DontChargeUlt then
		Agent:GiveUltimate(10)
	end

	--

	Enemy:Stun(Data.Stun)
	Enemy:Rotate(AgentPivot.Position)

	if Enemy:TimeSinceLastPivot() > 0.5 then
		Enemy:PivotTo(Enemy:GetPivot())
	end

	if Data.Knockback then
		local Direction = Data.Knockback[1]
		local Power = Data.Knockback[2]
		local Time = Data.Knockback[3]

		Enemy:Knockback(Direction, Power, Time)
		Replicator:Knockback(Enemy, Direction, Power, Time)
	end

	if Is_Dazed then
		Enemy:EnterDazedState()
		Replicator:EnterDaze(Enemy)
	end

	if Burst_Damage > 0 then
		Replicator:DisplayDamage(Enemy, Burst_Damage, false, Data.Affliction, true)
	end

	Replicator:FillAffliction(Enemy, Data.Affliction, Affliction_Fill)
	Replicator:DisplayDamage(Enemy, Dealt_Damage, Critical, Affliction)
	Replicator:DazeEnemy(Enemy, Dealt_Daze)

	--
	return {
		Enemy = Enemy,
		Caster = Agent,
		Type = Data.Affliction,
		Damage = Dealt_Damage,
		Burst = Affliction_Triggered,
		IsKill = EnemyDied,
		Hit_Type = 'Entity',
	}
end

local function HitAgent(Caster: Types.ServerEnemyClass, Agent: AgentTypes.ServerAgentClass, Data: Types.HitEnemyData)
	Agent:Hit(Caster, 0.35)
	Agent:TakeDamage(Data.Damage)

	--
	return {
		Caster = Caster,
		Enemy = Agent,
		Hit_Type = 'Entity',
	}
end

local function HitStructure(Caster, Structure, Data)
	Structure:TakeDamage(Caster, Data.Damage)

	return {
		Hit_Type = 'Structure',
	}
end

function ServerAbilityClass:Hit(Agent: any, Enemy: any, Data: Types.HitEnemyData)
	local Result;

	if tostring(Enemy) == 'ServerAgentClass' then
		Result = HitAgent(Agent, Enemy, Data)
	elseif tostring(Enemy) == 'EnemyClass' then
		Result = HitEnemy(Agent, Enemy, Data)
	else
		Result = HitStructure(Agent, Enemy, Data)
	end

	if Result ~= nil then
		self.__Hit:Fire(Result)
	end
end

function ServerAbilityClass.ForOtherAgents(self: Types.ServerAbilityClass, Agent: AgentTypes.ServerAgentClass, Callback: (Agent: AgentTypes.ServerAgentClass, Data: {any}) -> ())
	local Player = Agent.__Player_Assigned
	local RepId = Player:GetAttribute("ReplicationId") :: number
	local AgentsTotal = AgentsLibrary:GetAll(RepId)
	local _, CurId = AgentsLibrary:GetCurrentActive(RepId)

	local Next = CurId + 1
	if Next > 3 then Next = 1 end

	for id, OtherAgent in AgentsTotal do
		local AgentData = {
			IsNext = id == Next,
		}

		task.spawn(Callback, OtherAgent, AgentData);
	end
end


function ServerAbilityClass:FromData(Key: string, Sub_Key: number, GivenLevel: number?): ()
	if Key == 'Knockback' then
		return {self:FromData('Knockback_Direction'), self:FromData('Knockback_Strength'), self:FromData('Knockback_Time')}
	end

	local Base = self.__Ability_Data.Base
	local Upgrade = self.__Ability_Data.Upgrades or {}

	local Level = math.max((GivenLevel or 1) - 1, 0)
	local Value = Base[Key] or 0
	local Upgraded_Value = Upgrade[Key]

	if typeof(Value) == 'table' and Sub_Key ~= nil then
		local Added = Upgraded_Value ~= nil and Upgrade[Key][Sub_Key] or 0

		return Value[Sub_Key] + Added * Level
	end

	if Key == "Speed" and Value == nil then
		Value = 1
	end

	return Value
end

function ServerAbilityClass.Cancel(self: Types.ServerAbilityClass, Caster: AgentTypes.ServerAgentClass, Callback: () -> ())
	if Callback then
		task.spawn(Callback)
	end

	--
	local SkillId = GameEnum.Skills[self.__Name]
	if not SkillId then
		return;
	end

	Replicator:UseSkill(Caster.__Player_Assigned, SkillId, true, 0, 2)
end

function ServerAbilityClass:SetData(Data: {})
	self.__Ability_Data = Data
end

return ServerAbilityClass
