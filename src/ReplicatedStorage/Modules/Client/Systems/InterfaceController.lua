--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

--
local Player = Players.LocalPlayer

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client


--
local Controller = {}

function Controller:Init()
	local PlayerGui = Player.PlayerGui:WaitForChild('PlayerHUD'):FindFirstChild('Screen')
	
	for _, Component in Client.Components.Interface:GetChildren() do
		local GUIObject = PlayerGui:FindFirstChild(Component.Name) 
		local Object = require(Component)
		
		if GUIObject and tostring(Object) == 'GUIComponent' then
			Object:Link(GUIObject)
			task.spawn(Object.Init, Object)
		end
		
	end
	
end

return Controller
