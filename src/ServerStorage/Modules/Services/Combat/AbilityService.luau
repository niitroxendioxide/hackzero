--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Clock = require(Shared.Utility.Clock)
local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Network = require(Shared.Network)
local Enemies = require(Shared.Libraries.Enemies)
local GameEnum = require(Shared.GameEnum)
local AbilityTypes = require(Shared.Types.Abilities)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)
local MatchStats = require(ServerStorage.Modules.Libraries.MatchStats)
local MovesetLibrary = require(ServerStorage.Modules.Libraries.Movesets)
local QuestService = require(ServerStorage.Modules.Services.Data.QuestService)

--
local HELP_ASSIST_PROMPT_TIME = 1.25

--
local Service = {
	__Movesets = {},
	__Prompts = {},
	__Prompt_Cooldown = {},
	__Total_Damage = 0
}

function UpdateQuestData(Data: {[any]: any}, AgentPlayer: Player)
	Service.__Total_Damage += Data.Damage

	local PlayerCombatQuests = QuestService:GetPlayerQuestsWithGoals(AgentPlayer, {
		["Kill"] = true,
		["Damage"] = true,
	})

	MatchStats:AddToStat(AgentPlayer, "Kills", Data.IsKill and 1 or 0)

	if Data.IsKill and PlayerCombatQuests["Kill"] then
		local KillQuests = PlayerCombatQuests["Kill"]

		local TargetName = Data.Enemy.__Name

		for _, KillQuest in KillQuests do
			local Kills = KillQuest.Progress.Kill

			if Kills[TargetName] then
				Kills[TargetName] += 1
				continue
			elseif Kills.Any then
				Kills.Any += 1
			end
		end
	end
end

function HandleSkillHit(Data: AbilityTypes.AbilityHitInfo, SkillId: number)
	local Agent = Data.Caster :: AgentTypes.ServerAgentClass
	if not Agent or Data.Hit_Type ~= 'Entity' then return end
	local AgentPlayer = Agent.__Player_Assigned

	if not AgentPlayer then return end

	if SkillId == GameEnum.Skills.EX_Special then
		local is_enemy_stunned = Data.Enemy.__Status:IsKnocked()
		
		if is_enemy_stunned then
			Replicator:PromptChainAttack(Agent, Data.Enemy)
		end
	end

	task.spawn(UpdateQuestData, Data, Agent)
end

function Service:Init()
	--MovesetLibrary:Init()

	Network.new("Ability", "Event")
	Network:On('Ability', Service.ReplicateEvent)

	Clock:ThreadLoop(.5, function(delta: number)
		for _, Agent in AgentLibrary:GetActiveAgents() do
			if Agent:IsBeingAttacked() and not Service.__Prompt_Cooldown[Agent] then
				Service.__Prompt_Cooldown[Agent] = true

				Service:PromptAssist(Agent, HELP_ASSIST_PROMPT_TIME)

				task.delay(HELP_ASSIST_PROMPT_TIME, function()
					Service.__Prompt_Cooldown[Agent] = false
				end)
			end
		end
	end)

	--
	for _, Moveset in MovesetLibrary:GetAll() do
		local Skills = Moveset:GetAll()

		for _, Skill in Skills do
			Skill.__Hit:Connect(HandleSkillHit)
		end
	end
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer, ...)
	local Type = buffer.readu8(ClientBuffer, 0)

	if Type == GameEnum.Replication.UseSkill then
		local SkillId = buffer.readu8(ClientBuffer, 1)
		local EnemyId = buffer.readu8(ClientBuffer, 2)
		local StateId = buffer.readu8(ClientBuffer, 3)

		local Result = Service:PlaySkill(Player, SkillId, EnemyId, StateId, ...)

		if not Result then
			-- cancel here
			print("Cancel the current move!")
		end
	end

	return;
end

function Service:PromptAssist(CasterAgent: AgentTypes.ServerAgentClass, Time: number)
	local ReplicationId = CasterAgent.__Player_Assigned:GetAttribute("ReplicationId")
	local AllAgents = AgentLibrary:GetAlive(ReplicationId)
	local CurId = table.find(AllAgents, CasterAgent)
	local AgentToSwitch = CurId + 1 > 3 and AllAgents[1] or AllAgents[CurId + 1]
	local AgentPerpetratorId = CasterAgent.__Last_Hit_Caster

	if AgentPerpetratorId == nil then
		return
	end

	local EnemyExists = Enemies:GetEnemy(AgentPerpetratorId)
	if not EnemyExists or AgentToSwitch == CurId then
		return
	end

	--
	local Player = CasterAgent.__Player_Assigned
	local Prompt = CasterAgent:MarkTarget(AgentPerpetratorId, Time)
	Replicator:PromptAssist(Player, AgentToSwitch, Time, AgentPerpetratorId)

	Prompt.Accepted:Once(function()
		CasterAgent:MarkTarget(nil)

		Service:PlaySkill(Player, GameEnum.Skills.Quick_Assist, AgentPerpetratorId, 1)
	end)
end

function Service:PlaySkill(Player: Player, SkillId: number, EnemyId: number, StateId: number, ...)
	local ReplicationId = Player:GetAttribute("ReplicationId") :: number
	local ActiveAgent, _ = AgentLibrary:GetCurrentActive(ReplicationId)
	local Other = {...}

	local Moveset = Service:GetMoveset(ActiveAgent.Name)
	local Skill = GameEnum.KeyLookup(GameEnum.Skills, SkillId)
	local Enemy = Enemies:GetEnemy(EnemyId)
	local XZ = Vector3.new(1, 0, 1)

	--
	local LookAt = ActiveAgent:GetPivot().LookVector
	if Enemy then
		LookAt = CFrame.lookAt(ActiveAgent:GetPivot().Position * XZ, Enemy:GetPivot().Position * XZ).LookVector
	end

	-- Skill behavior
	local SpacelessSkill = string.gsub(Skill, '_', ' ')

	local Info = Moveset:GetInfoForSkill(SpacelessSkill)
	if SpacelessSkill ~= 'Dodge' and StateId == GameEnum.AbilityStates.Begin then
		ActiveAgent:Look(LookAt)

		if SpacelessSkill == "EX Special" then
			if ActiveAgent:GetEnergy() < Info.Base.Required_Energy then
				return false;
			end

			if (Info.Base.DontConsumeEnergy ~= true) then
				ActiveAgent:UseEnergy(Info.Base.Required_Energy)
			end
		elseif SpacelessSkill == "Ultimate" then
			if ActiveAgent:GetUltimate() < 100 then
				return false;
			end

			ActiveAgent:UseUltimate();
		end
	elseif SpacelessSkill == 'Dodge' then
		for _, Character in AgentLibrary:GetAll(Player:GetAttribute('ReplicationId') :: number) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end

	local Success, ErrorMessage = pcall(function()
		if (SkillId == GameEnum.Skills.Quick_Assist) or (SkillId == GameEnum.Skills.Dodge_Counter) then
			ActiveAgent:AddTag('Invulnerability', Statics.Assist_Counter_Invulnerability_Time)
		end

		if StateId == GameEnum.AbilityStates.Begin then
			if not Moveset:HasSkill(Skill) and SpacelessSkill == "Dodge" then
				MovesetLibrary:RunFromTemplate("Dodge", ActiveAgent)

				return
			end

			local _, Status = Moveset:Begin(Skill, ActiveAgent, {
				Target = Enemy, 
				M1_Count = Other and Other[1] or nil,
				Buffer = Other,
			})
			return Status
		elseif StateId == GameEnum.AbilityStates.End then
			Moveset:Release(Skill, ActiveAgent)
		elseif StateId == GameEnum.AbilityStates.Cancel then
			Moveset:CancelSkill(Skill, ActiveAgent, {ClientInstruction = true})
		end

		return ''
	end)

	if not Success then
		warn(`Error while executing skill: {SpacelessSkill}. Error Message: {ErrorMessage}`)
	else
		local IncludePlayer = SkillId == GameEnum.Skills.Quick_Assist or SkillId == GameEnum.Skills.Dodge_Counter
		Replicator:UseSkill(Player, SkillId, IncludePlayer, EnemyId, StateId)
	end


	return true;
end

function Service:GetMoveset(Name: string): AbilityTypes.MovesetClass
	return MovesetLibrary:Get(Name) or Service:GetMoveset("Goku")
end

return Service
