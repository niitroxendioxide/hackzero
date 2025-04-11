local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Assets = ReplicatedStorage.Assets.Interface

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local Effects = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)
local Notifications = ComponentClass.new("Notifications", "NTF")

-- Privates
local function RequestJoinParty(Code: string)
    Network:Fire("Party", GameEnum.PartyManaging.Join, Code)
end

--
function Notifications:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Parties", true)

    return Main
end

function Notifications:Add(TypeEnum: number, Data: {[number]: any}): ()
    local Type = GameEnum.KeyLookup(GameEnum.NotificationTypes, TypeEnum)
    local NewNotification = Assets.Lobby.Notifications:FindFirstChild(Type)

    if NewNotification then
        NewNotification = NewNotification:Clone() :: Frame & {UIScale: UIScale}
        NewNotification.Text = `{Data[2]} invited you to their party!`
        NewNotification.Parent = Notifications:GetFrame().List


        local IsDestroying = false;
        local function Destroy()
            if IsDestroying then return end;
            IsDestroying = true;

            NewNotification.JoinButton.Interactable = false;
            Effects:Tween(NewNotification.UIScale, {.25}, {Scale = 0})

            Effects:CleanUp(NewNotification, 0.25)
        end

        NewNotification.QuitButton.MouseButton1Click:Once(Destroy)
        NewNotification.JoinButton.MouseButton1Click:Once(function()
            RequestJoinParty(Data[1] :: string)
            Destroy()
        end)

        Effects:CleanUp(Destroy, Data[3])
    end
end

function Notifications:Init()
    print("Inited!")
end

return Notifications :: Types.UIComponent & {
    Add: (self: Types.UIComponent, TypeEnum: number, Data: {[string]: any}) -> (),
}
