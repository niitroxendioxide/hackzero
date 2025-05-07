--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Enemies = require(Shared.Libraries.Enemies)

local Types = require(Shared.Types)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Shared.Utility.Hitbox)
local Sequence = require(Shared.Utility.Sequence)
--local CharacterDatabase = require(Shared.Database.Characters)
local GameEnum = require(Shared.GameEnum)

local ServerHitboxUtil = require(ServerStorage.Modules.Libraries.Hitbox)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local DamageLibrary = require(ServerStorage.Modules.Libraries.Damage)
local WorldCamera = workspace:WaitForChild('Camera')

--
local ServerAbilityClass = {} :: {[string]: (self: Types.ServerAbilityClass, any) -> any, new: () -> Types.ServerAbilityClass}
ServerAbilityClass.__index = ServerAbilityClass

function ServerAbilityClass.new(): Types.ServerAbilityClass
	local self = setmetatable({}, ServerAbilityClass)
	self.__Cache = {}
	self.__Cooldown = Signal.new()
	self.__Signal = Signal.new()
	self.__Hit = Signal.new()
	self.__Ability_Data = {}

	return self
end

function ServerAbilityClass:Play(Agent: Types.ServerAgentClass)
	print(Agent.Name, 'Ability executed!')

	self:Begin(Agent, {})
end

function ServerAbilityClass:CreateHitbox(Caster: Types.ServerAgentClass | Types.ServerEnemyClass, Offset, Size, Event)
	if tostring(Caster) == 'EnemyClass' then
		return self:CreateAgentHitbox(Caster, Offset, Size, Event)
	elseif tostring(Caster) == 'AgentClass' then
		return self:CreateEnemyHitbox(Caster, Offset, Size, Event)
	end

	return;
end

function ServerAbilityClass:CreateEnemyHitbox(Agent: Types.ServerAgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.ServerEnemyClass) -> ())
	local EnemyHitboxes = Enemies:GetHitboxes()
	local AreaParts = Hitbox:GetPartsInArea({WorldCamera.Enemies}, Size, Agent:GetPivot() * CFrame.new(Offset))

	for _, Part in  AreaParts do
		local Enemy = EnemyHitboxes[Part]

		task.spawn(Event, Enemy)
	end
end

function ServerAbilityClass:CreateAgentHitbox(Enemy: Types.ServerEnemyClass, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.ServerAgentClass) -> ())
	ServerHitboxUtil:ForAgentsInZone(Size, Enemy:GetPivot() * CFrame.new(Offset), function(Target: Types.ServerAgentClass, ...)
		if Target:HasTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER) then
			print(Target.Name, 'DODGED')
			Target:RemoveTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)

			return
		end

		Event(Target, ...)
	end)
end

function ServerAbilityClass:Save(Agent: Types.AgentClass, Key: string, Value: any)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end
	
	if typeof(self.__Cache[Agent][Key]) ~= 'nil' and typeof(self.__Cache[Agent][Key]) ~= typeof(Value) then
		warn(`Given value for key "{Key}" is a type value than previous value ({Value} {typeof(Value)})`)
	end

	self.__Cache[Agent][Key] = Value
end

function ServerAbilityClass:Increase(Agent: Types.ServerAgentClass, Key: string, Data: {Rate: number?, Limit: number?})
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

function ServerAbilityClass:Get(Agent: Types.AgentClass, Key: string)
	if not self.__Cache[Agent] then
		self.__Cache[Agent] = {}
	end

	return self.__Cache[Agent][Key] 
end

function ServerAbilityClass:Begin(_: Types.AgentClass, Frames: Sequence.SequenceFrames): Types.Sequence
	local AbilitySequence = Sequence.new(Frames)
	AbilitySequence:SetSpeed(self:FromData('Speed') or 1)

	AbilitySequence:After(function()
		self.__Signal:Fire()
	end)

	return AbilitySequence:Start()
end

function ServerAbilityClass:Hit(Agent: Types.ServerAgentClass, Enemy: Types.ServerEnemyClass, Data: Types.HitEnemyData)
	--
	local AgentPivot = Agent:GetPivot()
	local _EnemyPivot = Enemy:GetPivot()


	--
	local Dealt_Damage, Critical, Affliction, Affliction_Fill, Burst_Damage, Affliction_Triggered = DamageLibrary:Deal(Agent, Enemy, Data)
	local Dealt_Daze, Is_Dazed = DamageLibrary:Daze(Agent, Enemy, Data.Daze)

	--
	local EnergyAmount = (Dealt_Damage / Enemy.__Status:GetStat("Max_Health")) / 1.25
	if not Data.DontChargeEnergy then
		Agent:GiveEnergy(EnergyAmount)
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
	self.__Hit:Fire({
		Enemy = Enemy,
		Agent = Agent,
		Type = Data.Affliction,
		Damage = Dealt_Damage,
		Burst = Affliction_Triggered,
	})
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

	if typeof(Value) == 'table' then
		local Added = Upgraded_Value ~= nil and Upgrade[Key][Sub_Key] or 0

		return Value[Sub_Key] + Added * Level
	end

	if Key == "Speed" and Value == nil then
		Value = 1
	end

	return Value
end

function ServerAbilityClass:SetData(Data: {})
	self.__Ability_Data = Data
end

return ServerAbilityClass
