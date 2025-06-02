--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

--
local Player = Players.LocalPlayer

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local Trove = require(Shared.Utility.Trove)
local Inputs = require(Client.Libraries.Inputs)
local AgentClass = require(Client.Classes.Agent)

local CameraLibrary = require(Client.Libraries.Camera)
local CharacterLibrary = require(Client.Libraries.Characters)
local CutscenesLibrary = require(Client.Libraries.Cutscenes)

local Replicator = require(Client.Controllers.ReplicationController)
local GameEnum = require(Shared.GameEnum)
local Places = require(Shared.Places)
local UIGroups = require(Client.Libraries.UIGroups)
local NavStates = require(Client.States.Navigation)
local SwapPackage = require(Client.Components.Movesets.Swap)

--
local INPUT_DIRECTIONS = {
	['Front'] = Vector3.new(0, 0, -1),
	['Back'] = Vector3.new(0, 0, 1),
	['Left'] = Vector3.new(-1, 0, 0),
	['Right'] = Vector3.new(1, 0, 0)
}

local Controller = {
	__HeldKeys = {},
	__Trove = Trove.new(),
	__CurrentMovementVector = Vector3.zero,
}

function Controller:Init(): ()
	local FightEnabled = Places:CanFight()
	if FightEnabled then
		Controller:SetupKeybinds();
	else
		CameraLibrary:SetTargetPart("HumanoidRootPart")
	end

	RunService:BindToRenderStep('PlayerControllerMainLoop', Enum.RenderPriority.Camera.Value, function(Delta: number)
		if not FightEnabled then
			local Character = Player.Character
			if not Character then return end

			local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
			if not Humanoid then return end

			local MovementBlocked = Player:HasTag("InParty") or NavStates:Get('Movement_Locked')

			if MovementBlocked then
				Humanoid.WalkSpeed = 0
				Humanoid.JumpPower = 0
			else
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
			end

			--
			CameraLibrary:SetSubject(Character)
			CameraLibrary:Update(Delta)

			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end

			return
		end

		local CurrentCharacter = CharacterLibrary:GetCurrent(Player:GetAttribute("ReplicationId"))
		local Direction = Controller:GetCurrentMovementDirection()

		if CurrentCharacter == nil then
			return
		end

		local Active = UIGroups:IsActive("END", "EndScreen")
		local HoldingKeys = not(UserInputService:IsKeyDown(Enum.KeyCode.Tab)) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)

		if HoldingKeys and not(Active) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end

		-- !selene: ignore
		workspace.CurrentCamera.CameraSubject = CurrentCharacter.__Character.Humanoid
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

		debug.profilebegin('Moving character')
		local CharacterState = CurrentCharacter:GetState()
		if CharacterState == "Attacking" then
			CameraLibrary:ChangePartTrackingType(2)
		else
			CameraLibrary:ChangePartTrackingType(1)
		end

		if CurrentCharacter:IsAlive() then
			if (Direction.Magnitude > 0 and not CutscenesLibrary:IsInCutscene()) then
				CurrentCharacter:Look(Direction.Unit)
				CurrentCharacter:Move()
			else
				CurrentCharacter:Stop()
			end

			CurrentCharacter.__Swapped = false
		else
			if not(CurrentCharacter.__Locked) and not CurrentCharacter.__Swapped then
				CurrentCharacter.__Swapped = true
				SwapPackage:Play(CurrentCharacter, 'Swap Forth', 'Begin')
			end
		end

		debug.profileend()

		CameraLibrary:SetSubject(CurrentCharacter:GetModel())
		CameraLibrary:Update(Delta)

		local At = CurrentCharacter:GetPivot()

		Replicator:Replicate(GameEnum.Replication.Rotate, CurrentCharacter:GetRotation())
		Replicator:Replicate(GameEnum.Replication.PivotTo, CurrentCharacter:GetPivot())

		--local Ping = Players.LocalPlayer:GetNetworkPing()
		task.delay(Replicator:GetPing(), function()
			CurrentCharacter.__ServerLocation = At
		end)
	end)
end

function Controller:AddAgent(Name: string)
	local NewCharacter = AgentClass.new(Name)

	NewCharacter:Init(Player)
	NewCharacter:SetVisible(false)

	CharacterLibrary:Add(Player:GetAttribute("ReplicationId"), NewCharacter)
end

function Controller:GetCurrentMovementDirection(): Vector3
	return workspace.CurrentCamera.CFrame:VectorToWorldSpace(Controller.__CurrentMovementVector) * Vector3.new(1, 0, 1)
end

function Controller:ForCharacters(Callback: (Character: Types.CharacterClass) -> ())

	for _, Character in CharacterLibrary:GetCharacters(Player:GetAttribute("ReplicationId")) do
		Callback(Character)
	end

end

function Controller:SetupKeybinds()
	for Key, Direction in INPUT_DIRECTIONS do
		Inputs:Bind('Move_'..Key, {
			Release = true,
			Callback = function(State: 'Begin' | 'End')
				if State == 'Begin'  and not Controller.__HeldKeys[Key] then
					Controller.__HeldKeys[Key] = true
					Controller.__CurrentMovementVector += Direction
				elseif Controller.__HeldKeys[Key] then
					Controller.__HeldKeys[Key] = false
					Controller.__CurrentMovementVector -= Direction
				end

				if Controller:GetCurrentMovementDirection().Magnitude > 0 then
					Replicator:Replicate(GameEnum.Replication.Move)
				else
					Replicator:Replicate(GameEnum.Replication.Stop)
				end
			end,
		})
	end

	Inputs:Bind('Jog', {
		Release = false,
		Callback = function(_: 'Begin' | 'End')
			local State = false
			Controller:ForCharacters(function(Character)
				Character:SetKey('Jog')
				State = Character:GetKey('Jog')
			end)

			Replicator:Replicate(GameEnum.Replication.KeySwitch, GameEnum.Agent_Keys.Jog, State)
		end,
	})

	Inputs:Bind('Sprint', {
		Release = false,
		Callback = function(_: 'Begin' | 'End')
			local CanRun = true
			if not (CharacterLibrary:GetCurrent(Player:GetAttribute("ReplicationId")) :: AgentTypes.AgentClass):GetKey('Jog') then
				CanRun = false
				Replicator:Replicate(GameEnum.Replication.KeySwitch, GameEnum.Agent_Keys.Jog, true)
			end

			--
			local State = false
			Controller:ForCharacters(function(Character)
				if not Character:GetKey('Jog') then
					Character:SetKey('Jog')

					return
				end

				Character:SetKey('Sprint')
				State = Character:GetKey('Sprint')
			end)

			if CanRun then
				Replicator:Replicate(GameEnum.Replication.KeySwitch,  GameEnum.Agent_Keys.Sprint, State)
			end
		end,
	})

	Inputs:Bind('TESTING', {
		Release = false,
		Callback = function(_: 'Begin' | 'End')
			(CharacterLibrary:GetCurrent(Player:GetAttribute("ReplicationId")) :: AgentTypes.AgentClass):SwitchState('Attacking', .5)
		end,
	})
end

return Controller
