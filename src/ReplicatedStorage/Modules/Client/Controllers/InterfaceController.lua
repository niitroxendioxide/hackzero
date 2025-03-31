--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local _UserInputService = game:GetService('UserInputService')
local _RunService = game:GetService('RunService')

local _Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client


--
local Controller = {
	__Components = {},
}

function Controller:Init(): ()
	for _, Component in Client.Components.Interface:GetChildren() do
		task.spawn(function()
			local Object = require(Component)

			if tostring(Object) == 'GUIComponent' and Object:Link() then
				task.spawn(Object.Init, Object)

				Controller.__Components[Component.Name] = Object
			end
		end)
	end
end

function Controller:GetComponent(Name: string): {}
	return Controller.__Components[Name]
end

return Controller
