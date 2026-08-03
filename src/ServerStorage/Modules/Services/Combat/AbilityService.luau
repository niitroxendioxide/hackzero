--
local HttpService = game:GetService("HttpService")
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
local AgentService = require(ServerStorage.Modules.Services.Combat.AgentService)
local QuestService = require(ServerStorage.Modules.Services.Data.QuestService)

--
const HELP_ASSIST_PROMPT_TIME = 1.25
const CHAIN_ATTACKS_ENABLED = true
const CHAIN_ATTACK_REQUIRE_STUN = true

--
local Service = {
	__Movesets = {},
	__Prompts = {},
	__Prompt_Cooldown = {},
	__Chain_Attack_Prompts = {},
	__Total_Damage = 0,
	__Chain_Attack_Cooldown = {},
	__Agent_Damage_Hooks = {} :: { [number]: { [string]: {Agent: AgentTypes.ServerAgentClass, Handler: () -> ()} } },
}


--- Private / Local functions
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
	local RepId = AgentPlayer:GetAttribute("ReplicationId") :: number
	local CurrentAgent = AgentLibrary:GetCurrentActive(RepId)

	-- Handle chain attacks!
	if SkillId == GameEnum.Skills.EX_Special and CHAIN_ATTACKS_ENABLED and #AgentLibrary:GetAlive(RepId) > 1 then
		local is_enemy_stunned = Data.Enemy.__Status:IsKnocked()
		
		if (CHAIN_ATTACK_REQUIRE_STUN and is_enemy_stunned) or (not CHAIN_ATTACK_REQUIRE_STUN) then
			for _, SubAgent in AgentLibrary:GetAlive() do
				SubAgent:GiveUltimate(Statics.Chain_Attack_Ult_Bar_Fill)
			end

			Service:PromptChainAttack(CurrentAgent, Data.Enemy)
		end
	end

	task.spawn(UpdateQuestData, Data, Agent)
end

function ConnectAbilityDamageHook(Agent: AgentTypes.ServerAgentClass, Id: string, fn: (Perpetrator: AbilityTypes.ServerEnemy, HitData: AbilityTypes.HitEnemyData) -> (AbilityTypes.HitEnemyData))
	assert(typeof(fn) == 'function', "Must provide a function as 3rd argument.")

	local AgentPlayer = Agent.__Player_Assigned
	local PlayerId = AgentPlayer:GetAttribute("ReplicationId")

	if Service.__Agent_Damage_Hooks[PlayerId] == nil then
		Service.__Agent_Damage_Hooks[PlayerId] = {}
	end

	Service.__Agent_Damage_Hooks[PlayerId][Id] = {
		Agent = Agent,
		Handler = fn,
	}
end

function DisconnectAbilityDamageHook(Agent: AgentTypes.ServerAgentClass, Id: string)
	local AgentPlayer = Agent.__Player_Assigned
	local PlayerId = AgentPlayer:GetAttribute("ReplicationId")

	if Service.__Agent_Damage_Hooks[PlayerId] == nil then
		return
	end

	Service.__Agent_Damage_Hooks[PlayerId][Id] = nil
end

--- Publics
function Service:RunAbilityDamageHooks(AgentHit: AgentTypes.ServerAgentClass, Perpetrator: AbilityTypes.ServerEnemy, HitData: AbilityTypes.HitEnemyData)
	if AgentHit == nil or AgentHit.__Player_Assigned == nil then
		return HitData
	end

	local AgentPlayer = AgentHit.__Player_Assigned
	local PlayerId = AgentPlayer:GetAttribute("ReplicationId")
	if Service.__Agent_Damage_Hooks[PlayerId] == nil then
		return HitData
	end
	
	for Id, Data in Service.__Agent_Damage_Hooks[PlayerId] do
		if (Data.Agent ~= AgentHit) then
			continue
		end

		return Data.Handler(Perpetrator, HitData)
	end

	return HitData
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

function Service:ConnectDamageHook(Agent: AgentTypes.ServerAgentClass, Id: string, fn: (Perpetrator: AbilityTypes.ServerEnemy, HitData: AbilityTypes.HitEnemyData) -> (AbilityTypes.HitEnemyData))
	return ConnectAbilityDamageHook(Agent, Id, fn)
end

function Service:DisconnectDamageHook(Agent: AgentTypes.ServerAgentClass, Id: string)
	return DisconnectAbilityDamageHook(Agent, Id)
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer, ...)
	local Type = buffer.readu8(ClientBuffer, 0)

	if Type == GameEnum.Replication.UseSkill then
		local SkillId = buffer.readu8(ClientBuffer, 1)
		local EnemyId = buffer.readu8(ClientBuffer, 2)
		local StateId = buffer.readu8(ClientBuffer, 3)
		local IsCancel = buffer.readu8(ClientBuffer, 4) == 1

		--print('[SERVER] Server received')
		if SkillId == GameEnum.Skills.Chain_Attack then
			warn('Cannot run chain attack with UseSkill')
			
			return;
		end

		local Result = Service:PlaySkill(Player, SkillId, EnemyId, StateId, IsCancel, ...)

		if not Result then
			-- cancel here
			print("Cancel the current move!")
		end
	elseif Type == GameEnum.Replication.UseChainAttack then
		local ChainAttackData = Service.__Chain_Attack_Prompts[Player]
		if not ChainAttackData then
			return warn("Cannot run without a prompt");
		end

		local EnemyId = ChainAttackData.EnemyId;

		--- Force the switch on the server
		AgentService:CharacterSwitch(Player, ClientBuffer, Enemies:GetEnemy(EnemyId), true);

		Service.__Chain_Attack_Cooldown[Player] = os.clock(); 
		Service.__Chain_Attack_Prompts[Player] = nil;

		local Result = Service:PlaySkill(Player, GameEnum.Skills.Chain_Attack, EnemyId, 1, false, ...)
		if not Result then
			print('Cancel the current move!')
		end

	elseif Type == GameEnum.Replication.CancelChainAttack then
		local Agent = AgentLibrary:GetCurrentActive(Player:GetAttribute("ReplicationId") :: number)

		Service.__Chain_Attack_Cooldown[Player] = os.clock();
		Service.__Chain_Attack_Prompts[Player] = nil;
		Agent:RemoveTag("Invulnerability")
	elseif Type == GameEnum.Replication.MatchAirborne then
		local Agent = AgentLibrary:GetCurrentActive(Player:GetAttribute("ReplicationId") :: number)
		
		local Time = buffer.readu16(ClientBuffer, 1) / 100
		if Time <= 0 then
			Agent:RemoveTag('Airborne')

			return;
		end

		Agent:AddTag('Airborne', Time)
	end

	return;
end

function Service:PromptChainAttack(Agent: AgentTypes.ServerAgentClass, Enemy: AgentTypes.Enemy)
	if Service.__Chain_Attack_Prompts[Agent.__Player_Assigned] then
		return
	end

	local TimeSince = Service.__Chain_Attack_Cooldown[Agent.__Player_Assigned] or 0
	if (os.clock() - TimeSince) < 1.5 then
		return;
	end
	
	local Id = HttpService:GenerateGUID()
	Service.__Chain_Attack_Prompts[Agent.__Player_Assigned] = {
		Id = Id,
		CasterAgent = Agent,
		PromptedAt = os.clock(),
		EnemyId = Enemy:GetId(),
	}

	task.delay(Statics.Chain_Attack_Invulnerability_Time, function()
		local Prompt = Service.__Chain_Attack_Prompts[Agent.__Player_Assigned];
		if Prompt and Prompt.Id == Id then
			Service.__Chain_Attack_Prompts[Agent.__Player_Assigned] = nil;
		end
	end)

	Agent:AddTag('Invulnerability', Statics.Chain_Attack_Invulnerability_Time)

	--
	Replicator:PromptChainAttack(Agent, Enemy)
end

function Service:TriggerMeterFullEvent(Id: number, CasterAgent: AgentTypes.ServerAgentClass)
	local name = CasterAgent.Name;
	local Moveset = MovesetLibrary:Get(name)

	if Moveset and Moveset:GetPassiveManager() ~= nil then
		Moveset:GetPassiveManager():OnPassiveFilled(Id, CasterAgent)
	end
end

function Service:PromptAssist(CasterAgent: AgentTypes.ServerAgentClass, Time: number, Target: number?, fn: () -> ())
	local ReplicationId = CasterAgent.__Player_Assigned:GetAttribute("ReplicationId")
	local AllAgents = AgentLibrary:GetAlive(ReplicationId)
	local CurId = table.find(AllAgents, CasterAgent)
	local AgentToSwitch = CurId + 1 > #AllAgents and AllAgents[1] or AllAgents[CurId + 1]
	local AgentIdToSwitch = CurId + 1 > #AllAgents and 1 or CurId + 1
	local AgentPerpetratorId = Target or CasterAgent.__Last_Hit_Caster

	if AgentPerpetratorId == nil then
		return
	end

	local EnemyExists = Enemies:GetEnemy(AgentPerpetratorId)
	if not EnemyExists or AgentToSwitch == CurId then
		return
	end

	--
	for _, Agent in AllAgents do
		Agent:GiveUltimate(Statics.Assist_Ult_Bar_Fill)
	end

	local Player = CasterAgent.__Player_Assigned
	local Prompt = CasterAgent:MarkTarget(AgentPerpetratorId, Time, AgentIdToSwitch)
	Replicator:PromptAssist(Player, AgentToSwitch, Time, AgentPerpetratorId)

	Prompt.Accepted:Once(function()
		CasterAgent:MarkTarget(nil)
		if fn then
			fn()
		end

		Service:PlaySkill(Player, GameEnum.Skills.Quick_Assist, AgentPerpetratorId, 1, false)
	end)
end

function Service:PlaySkill(Player: Player, SkillId: number, EnemyId: number, StateId: number, IsCancel: boolean, ...)
	local ReplicationId = Player:GetAttribute("ReplicationId") :: number
	local ActiveAgent, _ = AgentLibrary:GetCurrentActive(ReplicationId)
	local Other = {...}

	--print('Server got: ', GameEnum.KeyLookup(GameEnum.AbilityStates, StateId))

	---
	local Moveset = Service:GetMoveset(ActiveAgent.Name)
	local Skill = GameEnum.KeyLookup(GameEnum.Skills, SkillId)
	local Enemy = Enemies:GetEnemy(EnemyId)
	local XZ = Vector3.new(1, 0, 1)

	---
	local LookAt = ActiveAgent:GetPivot().LookVector
	if Enemy then
		LookAt = CFrame.lookAt(ActiveAgent:GetPivot().Position * XZ, Enemy:GetPivot().Position * XZ).LookVector
	end

	--- Skill behavior
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
				MovesetLibrary:RunFromTemplate("Dodge", ActiveAgent, {IsCancel = IsCancel})

				return
			end

			local _, Status = Moveset:Begin(Skill, ActiveAgent, {
				Target = Enemy, 
				M1_Count = Other and Other[1] or nil,
				Buffer = Other or {},
				IsCancel = IsCancel,
			})
			return Status
		elseif StateId == GameEnum.AbilityStates.End then
			Moveset:Release(Skill, ActiveAgent, {
				Target = Enemy,
				M1_Count = Other and Other[1] or nil,
				Buffer = Other or {},
				IsCancel = IsCancel,
			})
		elseif StateId == GameEnum.AbilityStates.Cancel then
			Moveset:CancelSkill(Skill, ActiveAgent, {ClientInstruction = true})
		end

		return ''
	end)

	if not Success then
		warn(`Error while executing skill: {SpacelessSkill}. Error Message: {ErrorMessage}`)
	else
		local IncludePlayer = SkillId == GameEnum.Skills.Quick_Assist or SkillId == GameEnum.Skills.Dodge_Counter

		Replicator:UseSkill(Player, SkillId, IncludePlayer, EnemyId, StateId, IsCancel, Other)
	end

	return true;
end

function Service:GetMoveset(Name: string): AbilityTypes.MovesetClass
	return MovesetLibrary:Get(Name) or Service:GetMoveset("Goku")
end

return Service
