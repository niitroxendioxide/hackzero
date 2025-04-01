local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client

local _Types = require(ReplicatedStorage.Modules.Shared.Types)
local ComponentClass = require(Client.Classes.Interface)

local PartyComponent = ComponentClass.new("Party", "Lobby")

function PartyComponent:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD") :: ScreenGui
	local Main = HUD:FindFirstChild("Party", true)

    print("hey!", Main)

    return Main
end

return PartyComponent