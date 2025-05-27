--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local _UserInputService = game:GetService('UserInputService')
local StarterGUI = game:GetService("StarterGui")
local _RunService = game:GetService('RunService')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Inputs = require(Client.Libraries.Inputs)

--
local Controller = {
	__Components = {},
}

function Controller:Init(): ()
	Controller:DisableCallback("ResetButtonCallback")

	for _, Component in Client.Components.Interface:GetDescendants() do
		if Component:IsA("Folder") then
			continue
		end

		task.spawn(function()
			local Object = require(Component) :: Types.UIComponent

			if Object.__type == 'GUIComponent' and Object:Bind() then
				task.spawn(Object.Init, Object)

				Controller.__Components[Component.Name] = Object
			end
		end)
	end

	Inputs:Bind("TESTING", {
		Callback = function(State)
			if State == "Begin" then
				Controller:GetComponent("EndScreen"):Set()
			end
		end
	})
end

function Controller:GetComponent(Name: string): Types.UIComponent
	return Controller.__Components[Name]
end

function Controller:DisableCallback(Id: string)
	task.spawn(function()
		repeat
			local success = pcall(function()
				StarterGUI:SetCore(Id, false)
			end)

			task.wait(1)
		until success
	end)
end

return Controller
