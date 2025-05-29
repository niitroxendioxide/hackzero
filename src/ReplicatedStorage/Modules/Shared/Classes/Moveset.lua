--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Cooldown = require(Shared.Utility.Cooldown)
local GameEnum = require(Shared.GameEnum)
--local SwapPackage = require(Client.Packages.Swap)

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

	return self
end

function MovesetClass:Assign(Type: string, Ability: Types.AbilityClass)
	if self.__Assigned[Type] ~= nil then
		return
	end

	self.__Assigned[Type] = Ability

	Ability.__Cooldown:Connect(function(Time: number, Agent: AgentTypes.AgentClass)
		local CooldownKey = self.Name..Type..Agent.Name

		if Cooldown:IsOn(CooldownKey) then return end

		Cooldown:Add(CooldownKey, Time)
	end)
end

function MovesetClass:Begin(Type: string, Agent: Types.GenericClass, IsSignal: boolean): boolean
	Type = Type:gsub('_', ' ')

	if not self.__Assigned[Type] then
		return false
	end

	if not self.__Last_Use[Agent] then
		self.__Last_Use[Agent] = {}
	end

	local Info = self:GetInfoForSkill(Type)

	-- Run client checks for correcting skill usage
	if not(IsSignal) and RunService:IsClient() then
		if Type == "Special" and Agent:GetEnergy() >= Info.Base.Required_Energy then
			Type = "EX Special"

			Info = self:GetInfoForSkill('EX Special')
		elseif Type == 'Ultimate' and Agent:GetUltBar() < 100 then
			return false
		end
	end

	--
	local CooldownKey = self.Name..Type..Agent.Name..Agent:GetId()

	if typeof(self.__Assigned[Type]) == 'table' and self.__Assigned[Type].Play then
		if not self:Verify(Agent, Type) then
			return false
		end

		if Cooldown:IsOn(CooldownKey) then return false end

		Cooldown:Add(CooldownKey, Info.Base.Cooldown)

		--local LastUse = self.__Last_Use[Agent][Type] or os.clock()

		--
		self.__Assigned[Type].__Held[Agent] = true

		if RunService:IsClient() then
			if not Type:match('Swap') then
				self.__Assigned[Type]:Connect(Agent, 1)
			end

			-- #TODO: FIX WTV THIS IS
			if Agent.BlockRotation ~= nil then
				Agent:BlockRotation(.075)
			end
		end

		if Type == 'Dodge' then
			Agent:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, .5)
		end

		self.__Assigned[Type]:Play(Agent, Type, 'Begin')
		self.__Last_Use[Agent][Type] = os.clock()

		--
		return true;
	else
		warn(`Moveset: "{self.Name} does not have a correct skill module assigned for: "{Type}."`)
	end

	return false;
end


function MovesetClass:Release(Type: string, Caster: AgentTypes.AgentClass)
	Type = Type:gsub('_', ' ')

	local Info = self:GetInfoForSkill(Type)

	if Type == 'Special' and Caster:GetCurrentSkill() == 'EX Special' then
		Type = "EX Special"

		Info = self:GetInfoForSkill('EX Special')
	end

	if typeof(self.__Assigned[Type]) == 'table' then
		if not(Info.Base.Release) then
			return false;
		end

		--print(`{Type} last used with agent: {Agent.Name} on:`.. os.clock() - LastUse)
		if RunService:IsClient() then
			print('Connecting type skill:', Type, ' as State: End')
			self.__Assigned[Type]:Connect(Caster, 2)
		end

		self.__Assigned[Type].__Held[Caster] = false
		self.__Assigned[Type]:Play(Caster, Type, 'End')
		self.__Last_Use[Caster][Type] = os.clock()


		return true;
	else
		warn(`Moveset: "{self.Name} does not have a correct skill module assigned for: "{Type}."`)
	end

	return false;
end

function MovesetClass:Verify(Agent: AgentTypes.AgentClass, Type: string)
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
