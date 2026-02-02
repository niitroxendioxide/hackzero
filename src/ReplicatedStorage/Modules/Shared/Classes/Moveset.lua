--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Shared = ReplicatedStorage.Modules.Shared

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types.Abilities)
local AgentTypes = require(Shared.Types.Agents)
local Cooldown = require(Shared.Utility.Cooldown)
local GameEnum = require(Shared.GameEnum)

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

function MovesetClass.GetAll(self: Types.MovesetClass): {Types.ServerAbilityClass}
	local List = {}

	for _, Ability in self.__Assigned do
		table.insert(List, Ability)
	end

	return List
end

function MovesetClass:Begin(Type: string, Agent: Types.Caster, Context: {IsSignal: boolean?, [string]: any}): boolean

	Type = Type:gsub('_', ' ')
	Context = Context or {}

	if not self.__Last_Use[Agent] then
		self.__Last_Use[Agent] = {}
	end

	local Info = self:GetInfoForSkill(Type)

	if (Type ~= 'Quick Assist' and Type ~= 'Chain Attack') and (Agent.HasTag and Agent:HasTag('Switching')) then
		return
	end

	-- Run client checks for correcting skill usage
	if not(Context.IsSignal) and RunService:IsClient() then
		if Type == "Special" and (Agent:GetEnergy() >= Info.Base.Required_Energy) then
			Type = "EX Special"

			Info = self:GetInfoForSkill('EX Special')
		elseif Type == 'Ultimate' and (Agent :: AgentTypes.AgentClass):GetUltBar() < 100 then
			return false
		elseif Type == 'Basic Attack' and Agent:HasTag('Dodge_Counter_Tag') then
			Type = 'Dodge Counter'
		end
	end

	if not self.__Assigned[Type] then
		warn(`Moveset: "{self.Name} does not have a correct skill module assigned for: "{Type}."`)
		return false
	end

	--
	local CooldownKey = self.Name..Type..Agent.Name..Agent:GetId()

	if typeof(self.__Assigned[Type]) == 'table' and self.__Assigned[Type].Play then
		local Verified = self:Verify(Agent, Type)

		if not Verified then
			return false
		end

		if Cooldown:IsOn(CooldownKey) then return false, 'In Cooldown' end

		if not Info.Base then
			error("Skill data is invalid. Make sure to have both Base{} and Upgrade{}")
		end

		if not(Info.Base.Release) or Info.Base.ForceCooldownOnBegin then
			Cooldown:Add(CooldownKey, Info.Base.Cooldown)
		end

		--local LastUse = self.__Last_Use[Agent][Type] or os.clock()	

		--
		self.__Assigned[Type].__Held[Agent] = true
		if RunService:IsClient() then
			if not Type:match('Swap') then
				local Enemy = self.__Assigned[Type]:Connect(Agent, 1, Context.IsCancel);
				
				if Context.Target == nil then
					Context.Target = Enemy;
				end
			end

			-- #TODO: FIX WTV THIS IS
			if (Agent :: AgentTypes.AgentClass).BlockRotation ~= nil then
				local Time = Info.Base.LockRotation == true and Info.Base.Attack_State_Time or .075
				
				Agent:BlockRotation(Time)
			end
		end

		if Type == 'Dodge' then
			Agent:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, Statics.Dodge_Active_Time)
		end

		self.__Assigned[Type]:Play(Agent, Type, 'Begin', Context)
		self.__Last_Use[Agent][Type] = os.clock()

		--
		return true;
	end

	return false;
end


function MovesetClass:Release(Type: string, Caster: AgentTypes.AgentClass, Context: {IsCancel: boolean})
	Type = Type:gsub('_', ' ')
	Context = Context or {}
		
	local Info = self:GetInfoForSkill(Type)

	if Type == 'Special' and Caster:GetCurrentSkill() == 'EX Special' then
		Type = "EX Special"

		Info = self:GetInfoForSkill('EX Special')
	end

	local CooldownKey = self.Name..Type..Caster.Name..Caster:GetId()

	if typeof(self.__Assigned[Type]) == 'table' then
		if not(Info.Base.Release) and not(Info.Base.ReleaseVerify) then
			return false;
		end

		if Info.Base.ReleaseVerify and not self:Verify(Caster, Type, true) then
			print('Not verified')
			return false;
		end

		if not(Info.Base.ForceCooldownOnBegin) then
			Cooldown:Add(CooldownKey, Info.Base.Cooldown)
		end

		--print(`{Type} last used with agent: {Agent.Name} on:`.. os.clock() - LastUse)
		if RunService:IsClient() then
			local Enemy = self.__Assigned[Type]:Connect(Caster, 2, Context.IsCancel);
			Context.Target = Enemy;
		end

		self.__Assigned[Type].__Held[Caster] = false
		self.__Assigned[Type]:Play(Caster, Type, 'End', Context)
		self.__Last_Use[Caster][Type] = os.clock()


		return true;
	else
		warn(`Moveset: "{self.Name} does not have a correct skill module assigned for: "{Type}."`)
	end

	return false;
end

function MovesetClass:HasSkill(Type: string)
	Type = Type:gsub('_', ' ')

	if not self.__Assigned[Type] then
		return false
	end

	return true
end

function MovesetClass:Verify(Agent: AgentTypes.AgentClass, Type: string, Release: boolean)
	local Info = self:GetInfoForSkill(Type)
	local CooldownKey = self.Name..Type..Agent.Name..Agent:GetId()
	if not string.match(Type, "Swap") and (Agent:GetState() ~= 'Idle' and not(Info.AllowedStates and Info.AllowedStates[Agent:GetState()])) and not Release then
		return false
	end

	if Cooldown:IsOn(CooldownKey) then

		return false
	end

	return true
end

function MovesetClass:GetSkillModule(Name: string)
	local NewKey = string.gsub(Name, "_", " ")

	return self.__Assigned[NewKey]
end

function MovesetClass:CancelSkill(SkillKey: string, Agent, Context)
	local SkillMod = self:GetSkillModule(SkillKey)

	if SkillMod then
		SkillMod:Cancel(Agent, Context)

		if RunService:IsClient() and (not Context or not Context.Hit)  then
			
			SkillMod:Connect(Agent, GameEnum.AbilityStates.Cancel)
		end
	end
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

	if not table.isfrozen(Data) then
		table.freeze(Data)
	end

	self.__Information = Data
end

return MovesetClass
