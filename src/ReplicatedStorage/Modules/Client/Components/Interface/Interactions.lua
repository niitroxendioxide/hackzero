local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client

local Types = require(ReplicatedStorage.Modules.Shared.Types)
local ComponentClass = require(Client.Classes.Interface)
local UIGroups = require(Client.Libraries.UIGroups)

local Interactions = ComponentClass.new("Interactions", "Lobby")
:: Types.UIComponent & {GetButton: (Name: string) -> (TextButton), SetButton: (Name: string, State: boolean) -> ()}

function Interactions:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD") :: ScreenGui
	local Main = HUD:FindFirstChild("Interactions", true)

    return Main
end

function Interactions:SetButton(Button: string, State: boolean)
    local ButtonObject = Interactions:GetButton(Button)
    if ButtonObject then
        ButtonObject.Visible = State
    end
end

function Interactions:GetButton(Name: string): Frame
    local Frame = self:GetFrame()

    return Frame:FindFirstChild(Name.."Button")
end

function Interactions:Init()
    local PlayButton = Interactions:GetButton("Play")

    PlayButton.PlayButton.MouseButton1Click:Connect(function()
        local PartyUI = UIGroups:GetElementClass("Lobby", "Party")

        PartyUI:Set(true)
        Interactions:SetButton("Play", false)
    end)
end

function Interactions:Set()
    self:GetFrame().Visible = true
end

return Interactions