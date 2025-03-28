--
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Settings = require(Client.Packages.Settings)
local Types = require(Shared.Types)

local LocalPlayer = Players.LocalPlayer

local KEY_ACTIONS = {'moveForward', 'moveBackward', 'moveRight', 'moveLeft', 'jump'}

--
local Inputs = {
	__Bound = {},
}

function Inputs:Init()
	LocalPlayer.CharacterAdded:Connect(Inputs.OverrideDefaults)
	UserInputService.InputBegan:Connect(Inputs.OnEvent)
	UserInputService.InputEnded:Connect(Inputs.OnEvent)
	
	if LocalPlayer.Character then
		Inputs.OverrideDefaults()
	end
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
	for _, Action in KEY_ACTIONS do
		ContextActionService:UnbindAction(Action..'Action')
	end
end

function Inputs:Bind(Key: string, Data: Types.KeybindData): (number, Types.BoundKeybind)
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

function Inputs:GetEnumFromKey(Name: string)
	return Settings.Keybinds.Computer[Name]
end

function Inputs:IsEnumKeyDown(Key: Enum.KeyCode)
	return UserInputService:IsKeyDown(Key)
end

return Inputs
