--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Network = require(Shared.Network)
local Enemies = require(Shared.Libraries.Enemies)
local GameEnum = require(Shared.GameEnum)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)
local MovesetLibrary = require(ServerStorage.Modules.Libraries.Movesets)
local AgentService = require(script.Parent.AgentService)

--
local Service = {
	__Movesets = {},
	__Prompts = {},
}

function Service:Init()
	MovesetLibrary:Init()

	Network.new("Ability", "Event")
	Network:On('Ability', Service.ReplicateEvent)
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer)
	local Type = buffer.readu8(ClientBuffer, 0)

	if Type == GameEnum.Replication.UseSkill then
		local SkillId = buffer.readu8(ClientBuffer, 1)
		local EnemyId = buffer.readu8(ClientBuffer, 2)
		local StateId = buffer.readu8(ClientBuffer, 3)

		local Result = Service:PlaySkill(Player, SkillId, EnemyId, StateId)

		if not Result then
			-- cancel here
			print("Cancel the current move!")
		end
	end

	return;
end

function Service:PromptAssist(Agent: AgentTypes.ServerAgentClass, Time: number)
	local Player = Agent.__Player_Assigned
	if Service.__Prompts[Player] then
		task.cancel(Service.__Prompts[Player])
	end

	--
	AgentService.__Targets[Player] = 1
	Replicator:PromptAssist(Player, Agent, Time, 1)

	Service.__Prompts[Player] = task.delay(Time, function()
		AgentService.__Targets[Player] = nil
	end)
end

function Service:PlaySkill(Player: Player, SkillId: number, EnemyId: number, StateId: number)
	local ReplicationId = Player:GetAttribute("ReplicationId") :: number
	local ActiveAgent, _ = AgentLibrary:GetCurrentActive(ReplicationId)

	local Moveset = Service:GetMoveset(ActiveAgent.Name)
	local Skill = GameEnum.KeyLookup(GameEnum.Skills, SkillId)
	local Enemy = Enemies:GetEnemy(EnemyId)
	local XZ = Vector3.new(1, 0, 1)

	--
	local State = if StateId == 1 then 'Begin' else 'End'

	local LookAt = ActiveAgent:GetPivot().LookVector
	if Enemy then
		print(EnemyId)
		LookAt = CFrame.lookAt(ActiveAgent:GetPivot().Position * XZ, Enemy:GetPivot().Position * XZ).LookVector
	end

	if math.random(1, 2) == 1 then
		local AllAgents = AgentLibrary:GetAll(ReplicationId)
		local CurId = table.find(AllAgents, ActiveAgent)
		local AgentToSwitch = CurId + 1 > 3 and AllAgents[1] or AllAgents[CurId + 1]
		Service:PromptAssist(AgentToSwitch, 2)
	end

	-- Skill behavior
	local SpacelessSkill = string.gsub(Skill, '_', ' ')
	local Info = Moveset:GetInfoForSkill(SpacelessSkill)
	if SpacelessSkill ~= 'Dodge' then
		ActiveAgent:Look(LookAt)

		if SpacelessSkill == "EX Special" then
			if (State == 'Begin' and ActiveAgent:GetEnergy() < Info.Base.Required_Energy) then
				return false;
			end

			if (Info.Base.DontConsumeEnergy ~= true) then
				ActiveAgent:UseEnergy(Info.Base.Required_Energy)
			end
		elseif SpacelessSkill == "Ultimate" then
			if (State == 'Begin' and ActiveAgent:GetUltimate() < 100) then
				return false;
			end

			ActiveAgent:UseUltimate();
		end
	elseif SpacelessSkill == 'Dodge' then
		print(SpacelessSkill)

		for _, Character in AgentLibrary:GetAll(Player:GetAttribute('ReplicationId') :: number) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end

	if State == 'Begin' then
		Moveset:Begin(Skill, ActiveAgent)
	else
		Moveset:Release(Skill, ActiveAgent)
	end

	Replicator:UseSkill(Player, SkillId, false, EnemyId, StateId)

	return true;
end

function Service:GetMoveset(Name: string): Types.MovesetClass
	return MovesetLibrary:Get(Name) or Service:GetMoveset("Goku")
end

return Service
