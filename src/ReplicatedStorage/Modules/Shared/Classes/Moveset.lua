--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Cooldown = require(Shared.Utility.Cooldown)
local GameEnum = require(Shared.GameEnum)
local SwapPackage = require(Client.Packages.Swap)
local CharacterDatabase = require(Shared.Database.Characters)

--
local MovesetClass = {} :: {[string]: (self: Types.MovesetClass, any) -> any, new: () -> Types.MovesetClass}
MovesetClass.__index = MovesetClass

function MovesetClass.new(Name: string)
	local self = setmetatable({}, MovesetClass)
	self.Name = Name
	
	-- # Privates
	self.__Information = {}
	self.__Assigned = {}
	self.__Last_Use = {}
	
	if RunService:IsClient() then
		self:Assign('Swap Back', SwapPackage)
		self:Assign('Swap Forth', SwapPackage)
	end
	
	return self
end

function MovesetClass:Assign(Type: string, Ability: Types.AbilityClass)
	if self.__Assigned[Type] ~= nil then
		return
	end
	
	self.__Assigned[Type] = Ability
	
	Ability.__Cooldown:Connect(function(Time: number, Agent: Types.AgentClass)
		local CooldownKey = self.Name..Type..Agent.Name

		if Cooldown:IsOn(CooldownKey) then return end

		Cooldown:Add(CooldownKey, Time)
	end)
end

function MovesetClass:Begin(Type: string, Agent: Types.AgentClass, State: 'Begin' | 'End')
	Type = Type:gsub('_', ' ')
	
	if not self.__Assigned[Type] then
		return
	end
	
	if not self.__Last_Use[Agent] then
		self.__Last_Use[Agent] = {}
	end
	
	
	local Info = self:GetInfoForSkill(Type)
	local CooldownKey = self.Name..Type..Agent.Name..(Agent.PlayerId or Agent.__User or Agent.__EnemyId)
	
	if (typeof(self.__Assigned[Type]) == 'table' and self.__Assigned[Type].Play) then
		if not self:Verify(Agent, Type) then
			return
		end
		
		if Cooldown:IsOn(CooldownKey) then return end

		Cooldown:Add(CooldownKey, Info.Base.Cooldown)
		
		local LastUse = self.__Last_Use[Agent][Type] or os.clock()
		
		if self.__Assigned[Type].Holdable then
			self.__Assigned[Type].__Held = true
		end
		
		if RunService:IsClient() then
			if not Type:match('Swap') then
				self.__Assigned[Type]:Connect(Agent)
			end
			
			-- #TODO: FIX WTV THIS IS
			local _ = Agent.BlockRotation and Agent:BlockRotation(.075)
		end
		
		if Type == 'Dodge' then
			Agent:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, .5)
		end
		
		self.__Assigned[Type]:Play(Agent, Type, State)
		self.__Last_Use[Agent][Type] = os.clock()
	else
		warn(`Moveset: "{self.Name} does not have a correct skill module assigned for: "{Type}."`)
	end
end


function MovesetClass:Release(Type: string, Agent: Types.AgentClass)
	Type = Type:gsub('_', ' ')
	
	if (typeof(self.__Assigned[Type]) == 'table' and self.__Assigned[Type].__Holdable) then
		
		--print(`{Type} last used with agent: {Agent.Name} on:`.. os.clock() - LastUse)

		self.__Assigned[Type].__Held = false
	end
end

function MovesetClass:Verify(Agent: Types.AgentClass, Type: string)
	local Info = self:GetInfoForSkill(Type)
	
	if Agent:GetState() ~= 'Idle' and not(Info.AllowedStates and Info.AllowedStates[Agent:GetState()]) then
		return false
	end
	
	return true
end

function MovesetClass:GetInfoForSkill(Name: string)
	if self.__Information[Name] == nil then
		--warn('Information for moveset is nil')
		
		return {Base = {}, Upgrades = {}}
	end
	
	return self.__Information[Name]
end

function MovesetClass:SetAbilityInformation(Data: {})
	assert(#self.__Information == 0, 'Ability information is already set. Can\'t overwrite')
	
	self.__Information = table.freeze(Data)
end

return MovesetClass
