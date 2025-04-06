local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)

local PartyComponent = ComponentClass.new("Party", "Lobby")


--
local function RequestPartyCreation()
    print('Request to create sent')
    Network:Fire("Party", GameEnum.PartyManaging.Create)
end

local function RequestPartyLeave(): ()
    Network:Fire("Party", GameEnum.PartyManaging.Leave)
end

local function RequestPartyStageBegin(): ()
    Network:Fire("Party", GameEnum.PartyManaging.Start)
end

local function AddPlayerToList(PlayerName: string)
    local Main = PartyComponent:GetFrame()
    local Object = Assets.Lobby.Party.PlayerListObject:Clone()
    Object.PlayerName.Text = PlayerName
    Object.Parent = Main.Players
end

--
function PartyComponent:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:FindFirstChild("LobbyHUD") :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Party", true)

    return Main
end


function PartyComponent:Init(): ()
    local Frame = self:GetFrame() :: Frame & {QuitButton: TextButton, PlayButton: TextButton}

    Frame.QuitButton.MouseButton1Click:Connect(function()
        RequestPartyLeave()
    end)


    Frame.PlayButton.MouseButton1Click:Connect(function()
        if Frame.PlayButton:GetAttribute("State") == false then
            return
        end

        PartyComponent:SetButtonState("Play", false)
        RequestPartyStageBegin()
    end)
end

function PartyComponent:SetButtonState(ButtonName: string, State: boolean)
    local Frame = self:GetFrame() :: Frame

    local Button = Frame:FindFirstChild(ButtonName.."Button") :: TextButton
    if Button then
        local OriginalColor = Button:GetAttribute("OriginalColor") :: Color3
        if not OriginalColor then
            Button:SetAttribute("OriginalColor", Button.BackgroundColor3)
            OriginalColor = Button.BackgroundColor3
        end

        if State == false then
            local H, S, V = OriginalColor:ToHSV()
            Button.BackgroundColor3 = Color3.fromHSV(H, S * 0.7, V * 0.8)
        else
            Button.BackgroundColor3 = OriginalColor
        end

        Button:SetAttribute("State", State)
    end
end

function PartyComponent:CreateParty()
    return RequestPartyCreation()
end

function PartyComponent:AddPlayerToList(Name: string)
    return AddPlayerToList(Name)
end

return PartyComponent :: Types.UIComponent & {
    CreateParty: () -> ()
}