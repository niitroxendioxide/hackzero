--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local GameEnum = require(Shared.GameEnum)
local Heap = require(Shared.Utility.Heap)
local Types = require(Shared.Types.Agents)

--
local STUDIO_ENERGY_MULT = 10;
local StatusClass = {}
StatusClass.__index = StatusClass

function StatusClass.new(Base: Types.CharacterStats): Types.AgentStatusClass
	local self = setmetatable({}, StatusClass)

	self.__Base_Stats = Base
	self.__Effects = {}

	--
	self.__Meters = {}
	self.__Total_Effects = Heap.new(128)
	self.__Ultimate = 0
	self.__Energy = 0
	self.__Alive = true
	self.__Health = self:GetStat('Health')
	self.__Max_Health = self:GetStat('Health')

	return self
end

function StatusClass.Update(self: Types.AgentStatusClass, delta: number)
	local Energy_Regen_Rate = self:GetStat('Energy_Regeneration')
	local Boost_Rate = (1 + self:GetStatEffects('Energy_Regeneration')) * (RunService:IsStudio() and STUDIO_ENERGY_MULT or 1)

	self:GiveEnergy(Boost_Rate * Energy_Regen_Rate * delta)
end

function StatusClass.CreateMeter(self: Types.AgentStatusClass, Name: string, Data: {[string]: any})
	local Object = {
		Max = Data.Max or -1,
		Value = 0,
		Id = Data.Id,
		FillSpeed = Data.FillSpeed or 0,
		EmptySpeed = Data.EmptySpeed or 0,
		Name = Name,
		LastUpdate = os.clock(),

		Fill = false,
		Empty = false,
	}

	table.insert(self.__Meters, Object)
end

function StatusClass.SetMeterUpdateType(self: Types.AgentStatusClass, Name: string, Type: number, State: boolean, Handler: () -> ())
	for _, Meter in self.__Meters do
		if Meter.Name ~= Name then
			continue
		end

		if Type == GameEnum.Meter_States.Fill then
			Meter.Fill = State
			Meter.FilledHandler = Handler
		else
			Meter.EmptiedHandler = Handler
			Meter.Empty = State
		end
	end
end

function StatusClass.UpdateMeter(self: Types.AgentStatusClass, Name: string, Amount: number)
	for Key, Meter in self.__Meters do
		if Meter.Name ~= Name then
			continue
		end

		Meter.LastUpdate = os.clock()
		Meter.Value = math.clamp(Meter.Value + Amount, 0, Meter.Max)

		return Meter
	end

	return
end

function StatusClass.RemoveMeter(self: Types.AgentStatusClass, Name: string): ()
	for Key, Meter in self.__Meters do
		if Meter.Name == Name then
			table.remove(self.__Meters, Key)

			break
		end
	end
end

function StatusClass.GetAllMeters(self: Types.AgentStatusClass)
	return self.__Meters
end

function StatusClass.GiveUltimate(self: Types.AgentStatusClass, Amount: number)
	self:SetUltimate(self:GetUltimate() + Amount)
end

function StatusClass.UseUltimate(self: Types.AgentStatusClass, Mods: {}?)
	self:SetUltimate(0)
end

function StatusClass.GetUltimate(self: Types.AgentStatusClass): number
	return self.__Ultimate
end

function StatusClass.SetUltimate(self: Types.AgentStatusClass, Value: number)
	self.__Ultimate = math.clamp(Value, 0, 100)
end


-- # Health
function StatusClass.GetHealth(self: Types.AgentStatusClass): (number, number)
	return self.__Health, self.__Max_Health
end

function StatusClass.SetMaxHealth(self: Types.AgentStatusClass, Amount: number)
	self.__Max_Health = Amount
end

function StatusClass.Damage(self: Types.AgentStatusClass, Amount: number)
	assert(typeof(Amount) == 'number' and Amount >= 0, 'Cannot take negative damage')

	self.__Health = math.clamp(self.__Health - Amount, 0, self.__Max_Health)

	if self.__Health <= 0 then
		self.__Alive = false
	end
end

function StatusClass.Heal(self: Types.AgentStatusClass, Amount: number)
	assert(typeof(Amount) == 'number' and Amount >= 0, 'Cannot heal negative health')

	if not self.__Alive then
		return
	end

	self.__Health = math.clamp(self.__Health + Amount, 0, self.__Max_Health)
end

function StatusClass.Revive(self: Types.AgentStatusClass)
	self.__Alive = true
end

function StatusClass.IsAlive(self: Types.AgentStatusClass)
	return self.__Alive and self.__Health > 0
end

-- # Energy
function StatusClass.GetEnergy(self: Types.AgentStatusClass)
	return self.__Energy
end

function StatusClass.GiveEnergy(self: Types.AgentStatusClass, EnergyAdded: number)
	self:SetEnergy(self:GetEnergy() + EnergyAdded)
end

function StatusClass.SetEnergy(self: Types.AgentStatusClass, EnergyValue: number)
	self.__Energy = math.clamp(EnergyValue, 0, 100)
end

function StatusClass.UseEnergy(self: Types.AgentStatusClass, EnergyRemoved: number)
	self:SetEnergy(self:GetEnergy() - EnergyRemoved)
end

function StatusClass.GetStat(self: Types.AgentStatusClass, n)
	if n == 'Speed' then
		return 1
	end

	return self.__Base_Stats[n]
end

function StatusClass.AddEffect(self: Types.AgentStatusClass, Effect: Types.EffectParameters)
	if self.__Total_Effects:isEmpty() then
		return
	end

	if Effect.Tag and Effect.Unique then
		for _, Other in self.__Effects do
			if Other.Tag ~= nil and Other.Tag == Effect.Tag then
				Other.Remove();
			end
		end
	end

	local NewId = self.__Total_Effects:extract()

	if typeof(Effect.Value) == 'string' and Effect.Value:find("%%") and Effect.Type then
		local Number = tonumber(string.sub(Effect.Value, 1, #Effect.Value-1), 10)
		local Stat = self.__Base_Stats[Effect.Type]

		Effect.Value = Stat * (Number / 100)
	end

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

function StatusClass.GetEffect(self: Types.AgentStatusClass, Tag: string)
	for _, Effect in self.__Effects do
		if Effect.Tag == Tag then
			return Effect;
		end
	end

	return;
end

function StatusClass.RemoveEffect(self: Types.AgentStatusClass, Id: number)
	local PreviousEffect = self.__Effects[Id]
	if PreviousEffect ~= nil then
		self.__Effects[Id] = nil

		self.__Total_Effects:insert(Id)
	end
end

function StatusClass.GetStatEffects(self: Types.AgentStatusClass, Type: Types.Stat)
	local Amount = 0

	for _, Effect in self.__Effects do
		if Effect.Type == Type then
			Amount += Effect.Value
		end
	end

	return Amount
end

function StatusClass:GetArtifactBonus(_Type: string)
	return 1
end

function StatusClass:GetDriveBonus(_Type: string)
	return 1
end

function StatusClass:GetMultBonus(_Name: string)
	return 0
end


return StatusClass
