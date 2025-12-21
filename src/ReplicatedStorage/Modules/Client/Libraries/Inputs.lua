--
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local RunService = game:GetService("RunService")

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Settings = require(Client.Packages.Settings)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)
local Places = require(Shared.Places)

local LocalPlayer = Players.LocalPlayer

local KEY_ACTIONS = {'moveForward', 'moveBackward', 'moveRight', 'moveLeft', 'jump'}

--
local Inputs = {
	__Bound = {},
	__Focused_Type = nil,
	__BoundToInputChanged = {}
}

function Inputs:Init()
	LocalPlayer.CharacterAdded:Connect(Inputs.OverrideDefaults)
	UserInputService.InputBegan:Connect(Inputs.OnEvent)
	UserInputService.InputEnded:Connect(Inputs.OnEvent)
	UserInputService.LastInputTypeChanged:Connect(function(TypeChanged: Enum.UserInputType)  
		if TypeChanged == Enum.UserInputType.Gamepad1 then
			Inputs.__Focused_Type = Enum.UserInputType.Gamepad1
		else
			Inputs.__Focused_Type = Enum.UserInputType.Keyboard
		end

		for _, Function in Inputs.__BoundToInputChanged do
			task.spawn(Function, Inputs.__Focused_Type)
		end

		Inputs.OverrideDefaults()
	end)

	if LocalPlayer.Character then
		Inputs.OverrideDefaults()
	end

	if Places:CanFight() then
		local Required = require(Players.LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule"))
		Required:GetControls():Disable()
	end
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

function Inputs.OverrideDefaults()
	if not Places:CanFight() then
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

function Inputs:GetMovementVector()
	
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
