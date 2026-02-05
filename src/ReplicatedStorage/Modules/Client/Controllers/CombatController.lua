--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Replicator = require(ReplicatedStorage.Modules.Client.Libraries.Replicator)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local GameEnum = require(Shared.GameEnum)
local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local CutsceneLibrary = require(Client.Libraries.Cutscenes)
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local InterfaceController = require(Client.Controllers.InterfaceController)
--local Replicator = require(Client.Libraries.Replicator)

--local GameEnum = require(Shared.GameEnum)

--
local Controller = {
	__Abilities = {"Basic_Attack", "Dodge", "Swap_Forth", "Swap_Back", "Ultimate", "Special"},
	__State = false,
	__Chain_Attack_Prompt = {
		Thread = nil,
		Target = nil,
		Active = false,
	},
	__HoldingOnChainAttack = false,

	ChainAttackActionChosen = Signal.new() :: Signal.ScriptSignal<number>,
}

local DirectionChoices = {
	'Swap Back',
	'Swap Forth'
}

function Controller:Init()
	if not Places:CanFight() then
		return;
	end

	Movesets:Init()

	--
	Network:On("Cutscene", function(Type: number, CutsceneName: string)
		if Type == GameEnum.CutsceneStatus.Received then
			local CutsceneTimeoutTime = CutsceneLibrary:GetTimeoutTime(CutsceneName)

			CutsceneLibrary:Start(CutsceneName)

			Network:Fire("Cutscene", GameEnum.CutsceneStatus.Received, {
				TimeoutTime = CutsceneTimeoutTime
			})

			CutsceneLibrary:WaitCurrent()

			Network:Fire("Cutscene", GameEnum.CutsceneStatus.Finished)
		end
	end)

	--
	for _, Key in Controller.__Abilities do
		Inputs:Bind(Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				Controller:HandleInput(Key, State)
			end,
		})
	end
end

function Controller:RequestCutscene()
	
end

function Controller:IsChainAttackPromptActive(): boolean
	return Controller.__Chain_Attack_Prompt.Active
end

function Controller:EnterChainAttackPrompt(Target: number): ()
	if Controller.__Chain_Attack_Prompt.Thread then
		task.cancel(Controller.__Chain_Attack_Prompt.Thread)
	end

	Controller.__Chain_Attack_Prompt.Target = Target
	Controller.__Chain_Attack_Prompt.Active = true

	Controller.__Chain_Attack_Prompt.Thread = task.delay(Statics.Chain_Attack_Invulnerability_Time, function()
		Controller:LeaveChainAttackPrompt()
	end)
end

function Controller:LeaveChainAttackPrompt(): ()
	Controller.__Chain_Attack_Prompt.Active = false
	Controller.__Chain_Attack_Prompt.Target = nil

	if Controller.__Chain_Attack_Prompt.Thread and Controller.__Chain_Attack_Prompt.Thread ~= coroutine.running() then
		task.cancel(Controller.__Chain_Attack_Prompt.Thread)
	end

	Controller.__Chain_Attack_Prompt.Thread = nil
end

function Controller:SetCombatState(State: boolean, Key: number?)
	Controller.__State = State
end

function Controller:GetCurrentCharacter()
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local CurrentAgent = Characters:GetCurrent(UserId)

	return CurrentAgent
end

function Controller:HandleInput(Key: string, State: string)
	local UserId = Players.LocalPlayer:GetAttribute("ReplicationId")
	local CharacterMoveset = Movesets:Get(Characters:GetCurrentName(UserId))
	local CurrentAgent = Characters:GetCurrent(UserId)

	if Controller.__HoldingOnChainAttack then
		Controller.__HoldingOnChainAttack = false
		return
	end

	if (CurrentAgent == nil) or not(Controller.__State) or not CurrentAgent:IsAlive() then
		return
	end

	if string.match(Key, "Swap") and not CurrentAgent:CanSwitch() then
		return
	end

	if Controller:IsChainAttackPromptActive() then
		local InputType = if Key == 'Basic_Attack' then 1 elseif Key == 'Dodge' then 2 else nil;
		if not(State == 'Begin') then
			return
		end

		Controller.__HoldingOnChainAttack = true

		if InputType ~= nil then
			local LocalPlayerId = Players.LocalPlayer:GetAttribute('ReplicationId') :: number
			local Direction = InputType == 1 and 1 or -1
			local TargetObject = Enemies:GetEnemy(Controller.__Chain_Attack_Prompt.Target)
			local Result, NewAgentId = Characters:Switch(LocalPlayerId, Direction, TargetObject, true)
			if not Result then
				Replicator:Replicate(GameEnum.Replication.CancelChainAttack)

				return;
			end 


			local NewAgentObj = Characters:GetAgent(LocalPlayerId, NewAgentId)
			CharacterMoveset = Movesets:Get(NewAgentObj.Name)
			NewAgentObj:AddTag('Switching', 0.5)

			local Context = {Target = TargetObject}

			CharacterMoveset:Begin('Chain_Attack', NewAgentObj, Context)
			Replicator:Replicate(GameEnum.Replication.UseChainAttack, NewAgentId, Direction, NewAgentObj:GetRotation())
		else
			Replicator:Replicate(GameEnum.Replication.CancelChainAttack)
		end

		Controller:LeaveChainAttackPrompt()
		Controller.ChainAttackActionChosen:Fire(InputType)
		Controller.ChainAttackActionChosen:DisconnectAll()

		return;
	end

	if CurrentAgent:HasTag('Switching') then
		return
	end

	local Is_Cancel = false
	local CurrentSkill = CurrentAgent:GetCurrentSkill()
	if CurrentSkill == "Basic_Attack" and Key == "Dodge" then
		Is_Cancel = true
		CharacterMoveset:CancelSkill("Basic Attack", CurrentAgent)
	end

	local Success;	

	if CharacterMoveset:HasSkill(Key) then
		if State == 'Begin' then
			Success = CharacterMoveset:Begin(Key, CurrentAgent, {IsCancel = Is_Cancel})
		else
			Success = CharacterMoveset:Release(Key, CurrentAgent)
		end
	elseif Key == "Dodge" then
		Movesets:RunFromTemplate("Dodge", CurrentAgent, {IsCancel = Is_Cancel})
	end

	--
	if Success then
		local SkillInfo = CharacterMoveset:GetInfoForSkill(Key)

		if string.match(Key, 'Swap') then
			SkillInfo = {Base = {Cooldown = .25}}
			Key = "Swap_Forth"
		end

		if SkillInfo.Base and SkillInfo.Base.Cooldown then
			local Moveset = InterfaceController:GetComponent("Moveset")

			Moveset:PlayCooldown(Key, SkillInfo.Base.Cooldown)
		end
	end

	if Key == 'Dodge' then
		for _, Character in Characters:GetCharacters(UserId) do
			Character:SetKey('Sprint', true)
			Character:SetKey('Jog', true)
		end
	end
end

return Controller