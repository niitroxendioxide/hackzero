--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Enemies = require(Shared.Libraries.Enemies)

local Types = require(Shared.Types.Abilities)
local AgentTypes = require(Shared.Types.Agents)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Shared.Utility.Hitbox)
local Sequence = require(Shared.Utility.Sequence)
local GameEnum = require(Shared.GameEnum)

local ServerHitboxUtil = require(ServerStorage.Modules.Libraries.Hitbox)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local DamageLibrary = require(ServerStorage.Modules.Libraries.Damage)
local AgentsLibrary = require(ServerStorage.Modules.Libraries.Agents)
local MatchStats = require(ServerStorage.Modules.Libraries.MatchStats)
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

function ServerAbilityClass:CreateHitbox(Caster: AgentTypes.ServerAgentClass & AgentTypes.Enemy, Offset, Size, Event, Time: number?, Repeat: boolean?)
	local At = Caster:GetPivot()
	ServerHitboxUtil:ForStructuresInZone(Size,  At * CFrame.new(Offset), function(Structure)
		Event(Structure)
	end)

	--
	if tostring(Caster) == 'EnemyClass' then
		self:CreateAgentHitbox(Caster, Offset, Size, Event, Time, Repeat)
	elseif tostring(Caster) == 'ServerAgentClass' then
		self:CreateEnemyHitbox(Caster, Offset, Size, Event, Time, Repeat)
	end

	local Obj;
	Obj = {
		Debug = function()
			local Part = Instance.new("Part");
			Part.Size = Size;
			Part.CFrame = At * CFrame.new(Offset);
			Part.Transparency = 0.5
			Part.Anchored = true
			Part.CanCollide = false
			Part.Color = Color3.new(1)
			Part.Parent = workspace

			return Obj
		end,
	}

	return Obj;
end

function ServerAbilityClass:CreateEnemyHitbox(Agent: AgentTypes.ServerAgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: AgentTypes.Enemy) -> (), Time: number?, Repeat: boolean?)
	local Targets = {}

	local function Process()
		local EnemyHitboxes = Enemies:GetHitboxes()
		local AreaParts 	= Hitbox:GetPartsInArea({WorldCamera.Enemies}, Size, Agent:GetPivot() * CFrame.new(Offset))

		for _, Part in AreaParts do
			local Enemy = EnemyHitboxes[Part]

			if Targets[Enemy] == true then
				continue
			end

			if not Repeat then
				Targets[Enemy] = true
			end

			task.spawn(Event, Enemy)
		end
	end

	if Time then
		local Began = os.clock()

		task.spawn(function()
			while os.clock() - Began < Time do
				Process()

				task.wait(1/24)
			end
		end)
	else
		task.spawn(Process)
	end
end

function ServerAbilityClass:CreateAgentHitbox(Enemy: AgentTypes.Enemy, Offset: Vector3, Size: Vector3, Event: (Enemy: AgentTypes.ServerAgentClass) -> (), Time: number?, Repeat: boolean?)
	local Targets = {}

	local function Process()
		ServerHitboxUtil:ForAgentsInZone(Size, Enemy:GetPivot() * CFrame.new(Offset), function(Target: AgentTypes.ServerAgentClass, ...)
			if Targets[Target] then
				return
			end

			if not Repeat then
				Targets[Target] = true
			end

			if Target:HasTag('Invulnerability') or Target:GetCurrentSkill() == "Ultimate" then
				return
			end

			local Is_Dodge = Target:HasTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)
			if Is_Dodge or Target:HasTag(GameEnum.Boost_Effects.SWITCH_ASSIST_DODGE) then
				if Is_Dodge then
					Replicator:ProcessDodge(Target)
				else
					self:Effect('Dodge', {Target}, {Target.__Player_Assigned})
				end

				MatchStats:AddToStat(Target.__Player_Assigned, "Dodges", 1)

				Target:AddTag('Invulnerability', Statics.Dodge_Invulnerability_Time)
				Target:RemoveTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER)
				Target:RemoveTag(GameEnum.Boost_Effects.SWITCH_ASSIST_DODGE)

				return
			end

			Event(Target, ...)
		end)
	end

	if Time then
		local Began = os.clock()

		task.spawn(function()
			while os.clock() - Began < Time do
				Process()

				task.wait()
			end
		end)
	else
		task.spawn(Process)
	end
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

function ServerAbilityClass:Begin(Agent: AgentTypes.ServerAgentClass, Frames: Sequence.SequenceFrames, DontStart: boolean): Types.Sequence
	local Sequence_Speed = self:FromData('Speed') or 1
	local Agent_Speed = Agent:GetStat("Speed")

	local AbilitySequence = Sequence.new(Frames)
	AbilitySequence:SetSpeed(Sequence_Speed * Agent_Speed)

	AbilitySequence:After(function()
		self.__Signal:Fire()
	end)

	self:Save(Agent, 'CurrentPlayerSequence', AbilitySequence)

	if not DontStart then
		AbilitySequence:Start()
	end

	return AbilitySequence
end


-- Hit functions
local function HitEnemy(Agent: AgentTypes.ServerAgentClass, Enemy: AgentTypes.Enemy, Data: Types.HitEnemyData)
	local AgentPivot = Agent:GetPivot()
	-- local EnemyPivot = Enemy:GetPivot()


	--
	local Validated, Dealt_Damage, EnemyDied, Critical, Affliction, Affliction_Fill, Burst_Damage, Affliction_Triggered = DamageLibrary:Deal(Agent, Enemy, Data)
	if not Validated then
		return;
	end
	
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

	Enemy:Stun(Data.Stun, Data.Airborne)
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

local function HitAgent(Caster: AgentTypes.Enemy, Agent: AgentTypes.ServerAgentClass, Data: Types.HitEnemyData)
	local DealtDamage = DamageLibrary:DealEnemyToAgent(Caster, Agent, Data)

	--
	return {
		Caster = Caster,
		Enemy = Agent,
		Hit_Type = 'Entity',
		Damage = DealtDamage,
	}
end

local function HitStructure(Caster, Structure, Data)
	local IsKill = Structure:TakeDamage(Caster, Data.Damage)
	if IsKill and Caster.__Player_Assigned then
		MatchStats:AddToStat(Caster.__Player_Assigned, "Structures_Destroyed", 1)
	end

	return {
		Hit_Type = 'Structure',
	}
end

function ServerAbilityClass.Effect(self: Types.ServerAbilityClass, Name: string, Params: {any}, Targets: boolean | {})
	if typeof(Targets) == 'function' then
		local ActualTargets = {}
		for _, Player in Players:GetPlayers() do
			local CurrentAgent = AgentsLibrary:GetCurrentActive(Player:GetAttribute('ReplicationId'))

			local Result = Targets(Player, CurrentAgent)
			if Result == true then
				table.insert(ActualTargets, Player)
			end
		end

		Targets = ActualTargets
	end

	Replicator:Effect(Name, Params, Targets)
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

	return Result
end

function ServerAbilityClass.UseAttackData(self: Types.ServerAbilityClass, Sequence: Types.Sequence, Caster: Types.Caster, Data: {[number]: number}, Hitbox_Data: Types.HitboxAttackData)

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
		local Added = Upgraded_Value ~= nil and Upgrade[Key][Sub_Key]

		if Added then
			return Value[Sub_Key] + (Added * Level)
		else
			return Value[Sub_Key]
		end
	elseif typeof(Value) == 'table' and Sub_Key == nil and Upgraded_Value ~= nil then
		-- support for new architecture;
		local clonedTable = table.clone(Value);
		
		for key, val in Upgraded_Value do
			clonedTable[key] += (val * Level)
		end
		
		return clonedTable;
	end

	if Key == "Speed" and Value == nil then
		Value = 1
	end

	return Value
end

function ServerAbilityClass.ForceRelease(self: Types.ServerAbilityClass, Caster: AgentTypes.ServerAgentClass)
	--
	local SkillId = GameEnum.Skills[self.__Name]
	if not SkillId then
		return;
	end

	Replicator:UseSkill(Caster.__Player_Assigned, SkillId, true, 0, GameEnum.AbilityStates.End)
end

function ServerAbilityClass.Cancel(self: Types.ServerAbilityClass, Caster: AgentTypes.ServerAgentClass, Context: {ClientInstruction: boolean?})
	local CurrentPlayerSequence = self:Get(Caster, 'CurrentPlayerSequence') :: Types.Sequence
	if CurrentPlayerSequence then
		CurrentPlayerSequence:Destroy()
	end

	Caster:SwitchState("Idle", 0)

	local SkillId = GameEnum.Skills[self.__Name]
	if not SkillId or Context.ClientInstruction == true then
		return;
	end

	Replicator:UseSkill(Caster.__Player_Assigned, SkillId, true, 0, GameEnum.AbilityStates.Cancel)
end

function ServerAbilityClass:SetData(Data: {})
	self.__Ability_Data = Data
end

return ServerAbilityClass
