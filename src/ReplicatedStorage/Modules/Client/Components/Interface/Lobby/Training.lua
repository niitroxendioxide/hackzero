local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)

--
local Component = ComponentClass.new(script.Name, 'Training', {KeyToBind = Enum.KeyCode.J}) :: Types.UIComponent & Types.UIGetSetButton
local States = {}

--
function RequestCreateParty()
	Network:Fire("Training", 'CreateParty')
end

function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("Training", true)

	return Main;
end

function Component:Init()
	Component:BindToStateChange(function(State: boolean)
		if State == true then
			RequestCreateParty()

			task.wait(1)
			self:Set(false)
		end
	end)


end

return Component
