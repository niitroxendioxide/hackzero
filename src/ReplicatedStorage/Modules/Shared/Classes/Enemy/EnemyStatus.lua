--
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Signal = require(Shared.Utility.Signal)
local GameEnum = require(Shared.GameEnum)
local EnemyDatabase = require(Database.Enemies)
local ElementDatabase = require(Database.Weakness)

local Statics = require(Database.Statics)

--
local EnemyStatus = {}
EnemyStatus.__index = EnemyStatus

function EnemyStatus.new(Name: string, Level: number)
	local self = setmetatable({}, EnemyStatus)

	self.EnteredDazeState = Signal.new()

	local EnemyData = EnemyDatabase:GetEnemyData(Name)

	--
	self.__State = 'Idle'
	self.__Level = Level or 60
	self.__Daze = 0
	self.__Dazed = false
	self.__Stats = EnemyDatabase:GetStatsAtLevel(Name, self.__Level)
	self.__Health = Statics.Get_Health_By_Level(self.__Level, EnemyData.Stats.Health, EnemyData.Level_Stats.Health)

	self.__Max_Health = self.__Health
	self.__Max_Daze = self.__Stats.Daze
	self.__Effects = {}
	self.__Threads = {}

	self.__AfflictionMeter = {}
	self.__AfflictionTotalDamage = {}


	return self
end

function EnemyStatus:SwitchState(State: string, Time: number)
	if not table.find(GameEnum.Agent_States, State) then
		return warn('Tried to switch to invalid state')
	end

	local CurrentThread = self.__Threads['CurrentState']

	if typeof(CurrentThread) == 'thread' then
		task.cancel(CurrentThread)
	end

	self.__State = State

	self.__Threads['CurrentState'] = task.delay(Time, function()
		self.__State = 'Idle'

		self.__Threads['CurrentState'] = nil
	end)

	return;
end

function EnemyStatus:IsKnocked()
	return self.__Dazed
end

function EnemyStatus:IsAirborne()
	return self.__State == 'Airborne'
end

function EnemyStatus:Daze(Amount: number): boolean
	if self.__Dazed and Amount > 0 then
		return false
	end

	self.__Daze = math.clamp(self.__Daze + Amount, 0, self.__Max_Daze)

	if self.__Daze >= self.__Max_Daze then
		return true
	end

	return false;
end


function EnemyStatus:IsAlive(): boolean
	return self.__Health > 0
end

function EnemyStatus:GetHealth(): number
	return self.__Health
end

function EnemyStatus:GetState()
	return self.__State
end

function EnemyStatus:GetStat(Name: string)
	if Name == 'Max_Health' then
		return self.__Max_Health --self:GetStat('Health')
	elseif Name == 'Max_Daze' then
		return self.__Max_Daze
	end

	if not self.__Stats[Name] then
		return nil
	end

	return self.__Stats[Name] + self:GetStatEffects(Name)
end

function EnemyStatus:Damage(Amount: number)
	assert(typeof(Amount) == 'number' and Amount > 0, 'Cannot take negative damage')
	
	self.__Health = math.clamp(self.__Health - Amount, 0, math.huge)
end

function EnemyStatus:Heal(Amount: number)
	assert(typeof(Amount) == 'number' and Amount > 0, 'Cannot heal negative health')
	
	self.__Health = math.clamp(self.__Health + Amount, 0, math.huge)
end

function EnemyStatus:GetDamageTakenMultiplier()
	return 1
end

function EnemyStatus:GetResistanceMultiplier()
	return .15
end

function EnemyStatus:GetElementMultiplier(Element: Types.Element)
	local IsInWeakness = table.find(self.__Stats.Weakness, Element)
	local IsInStrengths = table.find(self.__Stats.Strength, Element)
	
	return (IsInWeakness and ElementDatabase.Weakness_Multiplier) or (IsInStrengths and ElementDatabase.Strength_Multiplier) or 1
end

function EnemyStatus:FillAffliction(Type: string, Amount: number): ()
	if not self.__AfflictionMeter[Type] then
		self.__AfflictionMeter[Type] = 0
	end
	
	self.__AfflictionMeter[Type] += Amount
	
	if typeof(Amount) == 'number' and math.sign(Amount) > 0 then
		if not self.__AfflictionTotalDamage[Type] then
			self.__AfflictionTotalDamage[Type] = {0, 0}
		end
		
		self.__AfflictionTotalDamage[Type][1] += Amount
		self.__AfflictionTotalDamage[Type][2] += 1
	end
end

function EnemyStatus:ResetAffliction(Type: string): ()
	self.__AfflictionMeter[Type] = 0
	self.__AfflictionTotalDamage[Type] = {0, 0}
end

function EnemyStatus:GetAffliction(Type: string): number
	return self.__AfflictionMeter[Type]
end

function EnemyStatus:GetAfflictionStackedDamage(Type: string): number
	local Table = self.__AfflictionTotalDamage[Type] or {0, 1}
	
	return Table[1] / Table[2]
end

function EnemyStatus:GetDazeMultiplier(): number
	return (self:GetStat('Daze_Multiplier') / 100)
end

function EnemyStatus:EnterDazedState(fn: (DazeValue: number) -> ())
	--print(debug.traceback())
	if self.__Dazed then
		return
	end

	--
	self.__Dazed = true

	local Daze_Length = self:GetStat('Daze_Length')
	local _Daze_Removed = self:GetStat('Max_Daze')
	local Level_Mult = self.__Level * Statics.Daze_Length_Level_Multiplier

	self.__Daze_Thread = RunService.Heartbeat:Connect(function(delta: number)
		if self.__Daze <= 0 then
			self.__Dazed = false
			self.__Daze_Thread:Disconnect()
			return
		end
		
		--
		local Loss = (self.__Max_Daze * Level_Mult * delta) / Daze_Length
		
		self:Daze(-Loss)
		
		if fn then
			fn(self.__Daze)
		end
	end)
end

function EnemyStatus.AddEffect(self: Types.EnemyStatus, Effect: Types.EnemyEffectParameters)
	if Effect.Tag and Effect.Unique then
		for _, Other in self.__Effects do
			if Other.Tag ~= nil and Other.Tag == Effect.Tag then
				Other.Remove();
			end
		end
	end

	if typeof(Effect.Value) == 'string' and Effect.Value:find("%%") and Effect.Type then
		local Number = tonumber(string.sub(Effect.Value, 1, #Effect.Value-1), 10)
		local Stat = self.__Base_Stats[Effect.Type]

		Effect.Value = Stat * (Number / 100)
	end

	local NewId = HttpService:GenerateGUID(false)
	local Callback = Effect.Callback

	local EffectObject = {
		Id = NewId,
		Type = Effect.Type,
		Time = Effect.Time,
		Tag = Effect.Tag,
		Value = Effect.Value,
		Created = os.clock(),

		Remove = function()
			self:RemoveEffect(NewId)

			if Callback then
				task.spawn(Callback, NewId)
			end
		end,
	}

	if Effect.Time then
		task.delay(Effect.Time, EffectObject.Remove)
	end

	self.__Effects[NewId] = EffectObject

	return EffectObject
end

function EnemyStatus.GetEffect(self: Types.EnemyStatus, Tag: string)
	for _, Effect in self.__Effects do
		if Effect.Tag == Tag then
			return Effect;
		end
	end

	return;
end

function EnemyStatus.RemoveEffect(self: Types.EnemyStatus, Id: number)
	local PreviousEffect = self.__Effects[Id]
	if PreviousEffect ~= nil then
		self.__Effects[Id] = nil
	end
end

function EnemyStatus.GetStatEffects(self: Types.EnemyStatus, Type: Types.Stat)
	local Amount = 0

	for _, Effect in self.__Effects do
		if Effect.Type == Type then
			Amount += Effect.Value
		end
	end

	return Amount
end


return EnemyStatus
