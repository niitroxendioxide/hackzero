--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local RunService = game:GetService("RunService")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Replicator = require(ReplicatedStorage.Modules.Client.Libraries.Replicator)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Environment = require(ReplicatedStorage.Modules.Shared.Environment)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local World = require(ReplicatedStorage.Modules.Shared.World)
local GameEnum = require(Shared.GameEnum)
local Inputs = require(Client.Libraries.Inputs)
local Movesets = require(Client.Libraries.Movesets)
local Characters = require(Client.Libraries.Characters)
local CutsceneLibrary = require(Client.Libraries.Cutscenes)
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local InterfaceController = require(Client.Controllers.InterfaceController)
local TargetStates = require(Client.States.Targets)
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
	__Max_Dodge_Count = 2,
	__Time_Per_Dodge = 1,
	__Last_Use_Key = {},

	CurrentDodgeData = {},
	ChainAttackActionChosen = Signal.new() :: Signal.ScriptSignal<number>,
}

function Controller:Init()
	if not Places:CanFight() then
		return;
	end

	Movesets:Init()

	Controller.CurrentDodgeData = {
		LastAttempt = os.clock(),
		LastAdded = os.clock(),
		Amount = 0,
	}

	RunService.Heartbeat:Connect(function(a0: number)
		local CurrentDodgeData = Controller.CurrentDodgeData
		local TimeSinceLast = (os.clock() - CurrentDodgeData.LastAdded)
		local Added = 0
		if TimeSinceLast > .85 then
			CurrentDodgeData.LastAdded = os.clock()
			Added += 1
		end

		local Prev = CurrentDodgeData.Amount
		CurrentDodgeData.Amount = math.clamp(CurrentDodgeData.Amount + Added, 0, Controller.__Max_Dodge_Count)

		if Prev ~= CurrentDodgeData.Amount then
			local UIElement = InterfaceController:GetComponent("Moveset")
			if not UIElement then return end

			UIElement:DisplayDodges(CurrentDodgeData.Amount, Controller.__Max_Dodge_Count)
		end

	end)

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

	Inputs:Bind("LockOn", {
		Callback = function()
			local Character = Players.LocalPlayer.Character;
			local CamPos = Camera:GetPivot().Position
			local MousePosition = Players.LocalPlayer:GetMouse().Hit.Position
			local Direction = CFrame.lookAt(CamPos, MousePosition).LookVector

			local HitboxRaycast = workspace:Raycast(CamPos, Direction * 1000, World:GetEnemyColliderParams())
			if HitboxRaycast then
				local Collider = HitboxRaycast.Instance;
				local RetrievedEnemy = Enemies:GetFromCollider(Collider)
				if RetrievedEnemy then
					local RootPart = RetrievedEnemy:GetModel().PrimaryPart
					if Camera.__LookAtPart == RootPart then
						TargetStates.Current_Target = nil
					else
						TargetStates.Current_Target = RetrievedEnemy
					end

					Camera:SetLookAtPart(RootPart)
				end
			else
				local _, NearestEnemy = Enemies:GetNearestEnemy(Character:GetPivot().Position, 100, true)
				if NearestEnemy then
					local RootPart = NearestEnemy:GetModel().PrimaryPart
					if Camera.__LookAtPart == RootPart then
						TargetStates.Current_Target = nil
					else
						TargetStates.Current_Target = NearestEnemy
					end

					Camera:SetLookAtPart(RootPart)
				end
			end
		end,
	})

	--
	for _, Key in Controller.__Abilities do
		Inputs:Bind(Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				local UsedKey = Key
				if Key == 'Basic_Attack' and #Environment.REPLACE_M1_INPUT_WITH > 3 then
					UsedKey = Environment.REPLACE_M1_INPUT_WITH
				end

				Controller:HandleInput(UsedKey, State)
			end,
		})
	end
end

function Controller:TryConsumeDodge()
	local Data = Controller.CurrentDodgeData;
	if (os.clock() - Data.LastAttempt) < (1 / 3) then
		return false
	end

	if Data.Amount > 0 then
		Data.Amount = math.clamp(Data.Amount - 1, 0, Controller.__Max_Dodge_Count)
		Data.LastAttempt = os.clock()
		Data.LastAdded = os.clock()

		local UIElement = InterfaceController:GetComponent("Moveset")
		if not UIElement then 
			return true 
		end

		UIElement:DisplayDodges(Data.Amount, Controller.__Max_Dodge_Count)

		return true
	end

	return false
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
			local Direction = InputType == 1 and -1 or 1
			local TargetId = Controller.__Chain_Attack_Prompt.Target
			local TargetObject = Enemies:GetEnemy(TargetId)
			local Result, NewAgentId, Seed = Characters:Switch(LocalPlayerId, Direction, TargetId, true)
			if not Result then
				Replicator:Replicate(GameEnum.Replication.CancelChainAttack)

				return;
			end 

			local NewAgentObj = Characters:GetAgent(LocalPlayerId, NewAgentId)
			CharacterMoveset = Movesets:Get(NewAgentObj.Name)
			NewAgentObj:AddTag('Switching', 0.5)

			local Context = {Target = TargetObject}

			CharacterMoveset:Begin('Chain_Attack', NewAgentObj, Context)
			Replicator:Replicate(GameEnum.Replication.UseChainAttack, NewAgentId, Seed, NewAgentObj:GetRotation(), Direction, true)
		else
			Replicator:Replicate(GameEnum.Replication.CancelChainAttack)
		end

		Controller.ChainAttackActionChosen:Fire(InputType)
		Controller.ChainAttackActionChosen:DisconnectAll()
		Controller:LeaveChainAttackPrompt()

		return;
	end

	if CurrentAgent:HasTag('Switching') then
		return
	end

	if Controller.__Last_Use_Key[Key] == nil then
		Controller.__Last_Use_Key[Key] = {
			Begin = 0,
			End = 0,
		}
	end

	if (os.clock() - Controller.__Last_Use_Key[Key][State]) < (1 / 8) then
		return
	end

	if Key == 'Dodge' and not (State == 'Begin') then
		return;
	end

	Controller.__Last_Use_Key[Key][State] = os.clock()

	local Is_Cancel = false
	local CurrentSkill = CurrentAgent:GetCurrentSkill()
	local DodgeConsumed = Key == 'Dodge' and Controller:TryConsumeDodge()
	if Key == 'Dodge' and not DodgeConsumed then
		return
	end

	if CurrentSkill == "Basic_Attack" and Key == 'Dodge' and DodgeConsumed then
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

		-- Support template skills
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