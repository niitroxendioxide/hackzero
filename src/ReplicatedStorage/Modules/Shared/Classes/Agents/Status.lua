--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local StatusClass = {}
StatusClass.__index = StatusClass

function StatusClass.new(Base: Types.CharacterStats): Types.AgentStatusClass
	local self = setmetatable({}, StatusClass)

	self.__Base_Stats = Base
	self.__Artifact_Set = {}
	self.__Card_Set = nil
	self.__Effects = {}

	--
	self.__Ultimate = 0
	self.__Energy = 0
	self.__Health = self:GetStat('Health')
	self.__Max_Health = self:GetStat('Health')

	return self
end

function StatusClass:Update(delta: number)
	local Energy_Regen_Rate = self:GetStat('Energy_Regeneration')
	local Boost_Rate = 10--self:GetEff()

	self:GiveEnergy(Boost_Rate * Energy_Regen_Rate * delta)
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
function StatusClass.GetHealth(self: Types.AgentStatusClass)
	return self.__Health, self.__Max_Health
end

function StatusClass.SetMaxHealth(self: Types.AgentStatusClass, Amount: number)
	self.__Max_Health = Amount
end

function StatusClass.Damage(self: Types.AgentStatusClass, Amount: number)
	assert(typeof(Amount) == 'number' and Amount >= 0, 'Cannot take negative damage')

	self.__Health = math.clamp(self.__Health - Amount, 0, self.__Max_Health)
end

function StatusClass.Heal(self: Types.AgentStatusClass, Amount: number)
	assert(typeof(Amount) == 'number' and Amount >= 0, 'Cannot heal negative health')

	self.__Health = math.clamp(self.__Health + Amount, 0, self.__Max_Health)
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
	return self.__Base_Stats[n]
end

function StatusClass:AddEffect()
	
end

function StatusClass:GetEffect()
	
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
