--
const ContextActionService = game:GetService('ContextActionService')
const ReplicatedStorage = game:GetService('ReplicatedStorage')
const UserInputService = game:GetService('UserInputService')
const Players = game:GetService('Players')
const ThirdPartyUserService = game:GetService("ThirdPartyUserService")

--
const Shared = ReplicatedStorage.Modules.Shared
const Client = ReplicatedStorage.Modules.Client

const Settings = require(Client.Packages.Settings)
const GameEnum = require(Shared.GameEnum)
const Types = require(Shared.Types)
const Places = require(Shared.Places)

const LocalPlayer = Players.LocalPlayer

const KEY_ACTIONS = {'moveForward', 'moveBackward', 'moveRight', 'moveLeft', 'jump'}
const JUMP_BTN_POS = UDim2.new(0.9, -95, 1, -100)
const JUMP_BTN_SIZE = UDim2.fromOffset(80, 80)
const ThumbstickController = require(script.ThumbstickSim);
local GlobalThumbstick = nil;

local ThumbstickState: boolean? = nil
const HUD_WAIT_TIMEOUT = 10

--- Readjusters:
const function SetupMobileThumbstick(IsMobile: boolean, Force: boolean?)
	if not Places:CanFight() then
		return
	end

	if not Force and ThumbstickState == IsMobile then
		return
	end

	local Gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not Gui then
		return
	end

	local PlayerHUD = Gui:FindFirstChild("PlayerHUD")
	if not PlayerHUD and IsMobile then
		-- Bounded: an untimed WaitForChild here yields forever inside Framework's pcall(Init),
		-- which leaves Inputs uninitialised with nothing printed to Output.
		PlayerHUD = Gui:WaitForChild("PlayerHUD", HUD_WAIT_TIMEOUT)
	end

	if not PlayerHUD then
		warn('[Inputs] No PlayerHUD, cannot set up the mobile thumbstick')
		return
	end

	local TouchControlFrame = PlayerHUD:FindFirstChild('TouchControlFrame')
	if not TouchControlFrame and IsMobile then
		TouchControlFrame = PlayerHUD:WaitForChild('TouchControlFrame', HUD_WAIT_TIMEOUT)
	end

	if not TouchControlFrame then
		warn('[Inputs] PlayerHUD has no TouchControlFrame, cannot set up the mobile thumbstick')
		return
	end

	if not IsMobile then
		if GlobalThumbstick ~= nil then
			GlobalThumbstick:Enable(false)
		else
			TouchControlFrame.Visible = false
		end
	else
		if GlobalThumbstick == nil then
			GlobalThumbstick = ThumbstickController.new()
		end

		-- Enable owns the frame's visibility now that the frame IS the thumbstick.
		GlobalThumbstick:Enable(true, TouchControlFrame)
	end

	ThumbstickState = IsMobile
end

const function RescaleJumpButton()
	local Gui = Players.LocalPlayer.PlayerGui
	if not Gui then
		return
	end;

	local TouchGui = Gui:FindFirstChild("TouchGui")
	local JumpButton = TouchGui:FindFirstChild('TouchControlFrame'):FindFirstChild('JumpButton')
	if JumpButton ~= nil then
		JumpButton.Size = JUMP_BTN_SIZE
		JumpButton.Position = JUMP_BTN_POS
	end
end

const function RescaleBaseScreens(IsTouch: boolean)
	local Gui = Players.LocalPlayer.PlayerGui
	if not Gui then
		return
	end;

	local LobbyGUI = Gui:FindFirstChild("LobbyHUD")
	if LobbyGUI then
		local Screen = LobbyGUI.Screen
		Screen.Size = UDim2.fromScale(1, IsTouch and 1.05 or 1)
		Screen.Position = UDim2.fromScale(0.5, IsTouch and 0.525 or 0.5)
	end
end

--
const Inputs = {
	__Bound = {},
	__Focused_Type = nil,
	__BoundToInputChanged = {},
	__IsMobile = false,
}

function Inputs:Init()
	LocalPlayer.CharacterAdded:Connect(Inputs.OverrideDefaults)
	UserInputService.InputBegan:Connect(Inputs.OnEvent)
	UserInputService.InputEnded:Connect(Inputs.OnEvent)
	UserInputService.LastInputTypeChanged:Connect(function(TypeChanged: Enum.UserInputType)
		if TypeChanged == Enum.UserInputType.Gamepad1 then
			Inputs.__Focused_Type = Enum.UserInputType.Gamepad1
		elseif TypeChanged == Enum.UserInputType.Touch then
			Inputs.__Focused_Type = Enum.UserInputType.Touch
		else
			Inputs.__Focused_Type = Enum.UserInputType.Keyboard
		end


		---
		for _, Function in Inputs.__BoundToInputChanged do
			task.spawn(Function, Inputs.__Focused_Type)
		end

		Inputs.OverrideDefaults()

		---
		const IsTouch = TypeChanged == Enum.UserInputType.Touch
		RescaleBaseScreens(IsTouch)

		if IsTouch then
			if Places:CanFight() then
				-- soon to be used
			else
				RescaleJumpButton()
			end
		end
	end)

	const DefaultPreferredInputIsTouch = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	Inputs.__IsMobile = DefaultPreferredInputIsTouch

	-- PreferredInput is the authoritative answer to "is this a touch player", and unlike
	-- LastInputTypeChanged it doesn't fire on every mouse move. It's what keeps __IsMobile fresh.
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		const IsTouch = UserInputService.PreferredInput == Enum.PreferredInput.Touch

		Inputs.__IsMobile = IsTouch
		SetupMobileThumbstick(IsTouch)
	end)

	if Places:CanFight() then
		local Required = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
		local Controls = Required:GetControls()

		if LocalPlayer.Character then
			Inputs.OverrideDefaults()
		end

		Controls:Disable()

		Inputs:OnInputTypeChanged(function(Type: Enum.UserInputType)
			Controls:Disable()

			SetupMobileThumbstick(Type == Enum.UserInputType.Touch)
		end)

		const PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
		PlayerGui.ChildAdded:Connect(function(Child: Instance)
			if Child.Name ~= "PlayerHUD" then
				return
			end

			task.defer(SetupMobileThumbstick, Inputs:IsMobile(), true)
		end)
	end

	---
	SetupMobileThumbstick(DefaultPreferredInputIsTouch)
	RescaleBaseScreens(DefaultPreferredInputIsTouch);
end

function Inputs:IsMobile(): boolean
	return Inputs.__IsMobile
end

function Inputs:OnInputTypeChanged(Func: (Type: Enum.UserInputType) -> ())
	table.insert(Inputs.__BoundToInputChanged, Func)
end

function Inputs:WaitFor(Key: Enum.KeyCode | Enum.UserInputType, MaxTime: number?): boolean
	local Pressed = false;
	local LimitTime = MaxTime or 10
	local Clock = os.clock()

	local Connection; do
		Connection = UserInputService.InputBegan:Connect(function(InputObject: InputObject, GP: boolean)
			if GP then return end

			if (InputObject.KeyCode == Key :: Enum.KeyCode) or (InputObject.UserInputType == Key :: Enum.UserInputType) then
				Connection:Disconnect()

				Pressed = true

				return
			end
		end)
	end

	repeat task.wait()
	until Pressed or (os.clock() - Clock >= LimitTime);

	if Connection then
		Connection:Disconnect()
	end

	return true;
end

function Inputs.OnEvent(InputObject: InputObject, GameProcessedEvent: boolean)
	if GameProcessedEvent then
		return
	end

	debug.profilebegin('Processing inputs')
	--print(Inputs.__Bound)

	for _, BoundObject: Types.BoundKeybind in Inputs.__Bound do
		local EnumObject = Inputs:GetEnumFromKey(BoundObject.Key)

		local IsKey = false

		if typeof(EnumObject) == 'table' then
			for _, Object in EnumObject do
				if InputObject.KeyCode == Object or InputObject.UserInputType == Object then
					IsKey = true
					break
				end
			end
		else
			IsKey = (EnumObject == InputObject.KeyCode) or EnumObject == InputObject.UserInputType
		end

		if IsKey then
			local Released = InputObject.UserInputState == Enum.UserInputState.End
			BoundObject.Held = not Released
			BoundObject.Time = not Released and os.clock() or BoundObject.Time

			if (BoundObject.Release and Released) or not Released then
				task.spawn(BoundObject.Callback, InputObject.UserInputState.Name)
			end
		end
	end

	debug.profileend()
end

function Inputs:EmulateBindPress(BindName: string, State: Enum.UserInputState?)
	local RawEnum = Inputs:GetEnumFromKey(BindName)
	if typeof(RawEnum) == 'table' then
		RawEnum = RawEnum[1] :: EnumItem
	end

	local KeyBind = RawEnum
	local UserInputType = RawEnum
	local IsType = RawEnum.EnumType == Enum.UserInputType
	if not IsType then
		UserInputType = Enum.UserInputType.Keyboard
	else
		KeyBind = Enum.KeyCode.None
	end

	local EmulatedObject: InputObject = {
		KeyCode = KeyBind,
		UserInputType = UserInputType,
		UserInputState = State or Enum.UserInputState.Begin,
		Delta = vector.zero,
		Position = vector.zero,
	}

	Inputs.OnEvent(EmulatedObject, false)
end

function Inputs.OverrideDefaults()
	if not Places:CanFight() or Inputs:IsMobile() then
		return;
	end

	for _, Action in KEY_ACTIONS do
		ContextActionService:UnbindAction(Action..'Action')
	end

	ContextActionService:UnbindAction('moveThumbstick')
end

function Inputs:Bind(Key: string | Enum.KeyCode | Enum.UserInputType, Data: Types.KeybindData): (number?, Types.BoundKeybind)
	--assert(Data, 'Cannot bind key to no action')
	assert(Data.Callback, 'Cannot bind key to no action')

	local Object = {
		Key = Key,
		Held = false,
		Release = Data.Release or false,
		Time = 0,

		Callback = Data.Callback,
	}

	table.insert(Inputs.__Bound, Object)

	return table.find(Inputs.__Bound, Object), Object
end

function Inputs:RemoveBind()

end

function Inputs:GetMovementVector(): Vector3
	if not GlobalThumbstick or not GlobalThumbstick.enabled then
		return Vector3.zero;
	end

	---
	local Relative = (workspace.CurrentCamera.CFrame:VectorToWorldSpace(GlobalThumbstick:GetMoveVector()) * Vector3.new(1, 0, 1)).Unit

	return Relative
end

function Inputs:GetEnumFromKey(Name: string | Enum.KeyCode)
	if typeof(Name) == "EnumItem" then
		return Name
	end

	local Device = Inputs:GetDevice()
	if Device == GameEnum.Device.Console then
		return Settings.Keybinds.Controller[Name]
	end

	return Settings.Keybinds.Computer[Name]
end

function Inputs:IsMBDown(mouseButton: Enum.UserInputType)
	return UserInputService:IsMouseButtonPressed(mouseButton)
end

function Inputs:GetDevice(): number
	if UserInputService.TouchEnabled  then
		return GameEnum.Device.Mobile
	elseif UserInputService.GamepadEnabled and (Inputs.__Focused_Type == Enum.UserInputType.Gamepad1) then-- and (not UserInputService.KeyboardEnabled or RunService:IsStudio()) then
		return GameEnum.Device.Console
	end

	return GameEnum.Device.Desktop
end

function Inputs:IsDevice(p_DeviceType: number)
	return p_DeviceType == Inputs:GetDevice()
end

function Inputs:IsEnumKeyDown(Key: Enum.KeyCode)
	return UserInputService:IsKeyDown(Key)
end

return Inputs
