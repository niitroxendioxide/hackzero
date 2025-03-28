--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local StatusClass = {}
StatusClass.__index = StatusClass

function StatusClass.new(Base: CharacterStats): Types.AgentStatusClass
	local self = setmetatable({}, StatusClass)
	
	self.__Base_Stats = Base
	self.__Artifact_Set = {}
	self.__Card_Set = nil
	self.__Effects = {}
	
	--
	self.__Energy = 20
	self.__Health = self:GetStat('Health')
	self.__Max_Health = self:GetStat('Health')
	
	return self
end

function StatusClass:Update(delta: number)
	local Energy_Regen_Rate = self:GetStat('Energy_Regeneration')
	local Boost_Rate = 0--self:GetEff()
	
	
	self:GiveEnergy(Boost_Rate * Energy_Regen_Rate * delta)
end

-- # Health
function StatusClass:GetHealth()
	return self.__Health, self.__Max_Health
end

function StatusClass:SetMaxHealth(Amount: number)
	self.__Max_Health = Amount
end

function StatusClass:Damage(Amount: number)
	assert(typeof(Amount) == 'number' and Amount > 0, 'Cannot take negative damage')

	self.__Health = math.clamp(self.__Health - Amount, 0, self.__Max_Health)
end

function StatusClass:Heal(Amount: number)
	assert(typeof(Amount) == 'number' and Amount > 0, 'Cannot heal negative health')

	self.__Health = math.clamp(self.__Health + Amount, 0, self.__Max_Health)
end

-- # Energy
function StatusClass:GetEnergy()
	return self.__Energy
end

function StatusClass:GiveEnergy(Energy: number)
	self.__Energy = math.clamp(self.__Energy + Energy, 0, 100)
end

function StatusClass:UseEnergy(Energy: number)
	self.__Energy = math.clamp(self.__Energy - Energy, 0, 100)
end

function StatusClass:GetStat(n)
	return self.__Base_Stats[n]
end

function StatusClass:AddEffect()
	
end

function StatusClass:GetEffect()
	
end

function StatusClass:GetArtifactBonus(Type: string)
	return 1
end

function StatusClass:GetWeaponBonus(Type: string)
	return 1
end

function StatusClass:GetMultBonus(Name: string)
	return 0
end


return StatusClass
