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
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end

	local Main = HUD:FindFirstChild("Interactions", true)

    return Main
end

function Interactions:SetButton(Button: string, State: boolean)
    if UIGroups:GetActiveElementName( "Lobby") ~= nil then
        State = false;
    end

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
    local Create = Interactions:GetButton("Create")
    local Join = Interactions:GetButton("Join")

    Create.Button.MouseButton1Click:Connect(function()
        local PartyUI = UIGroups:GetElementClass("Lobby", "Party")

        Interactions:SetButton("Create", false)
        Interactions:SetButton("Join", false)
        PartyUI:CreateParty()
    end)

    Join.Button.MouseButton1Click:Connect(function()
        local PartiesBrowserUI = UIGroups:GetElementClass("Lobby", "Parties")

        PartiesBrowserUI:LoadParties()
        Interactions:SetButton("Create", false)
        Interactions:SetButton("Join", false)
    end)
end

function Interactions:Set()
    self:GetFrame().Visible = true
end

function Interactions:WaitForClose(Handler: () -> ())
    Interactions.__FiringSignal = Handler
end

function Interactions:FireLeaveSignal()
    if typeof(Interactions.__FiringSignal) == "function" then
        task.defer(Interactions.__FiringSignal)
    end
end

return Interactions