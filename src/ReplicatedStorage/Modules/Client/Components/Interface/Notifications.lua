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
local function AcceptPartyInvite(Code: string)
    Network:Fire("Party", GameEnum.PartyManaging.AcceptInvite, Code)
end

local function RejectPartyInvite(Code: string)
    Network:Fire("Party", GameEnum.PartyManaging.RejectInvite, Code)
end


--
function Notifications:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Notification", true)

    return Main
end

function Notifications:Add(TypeEnum: number, Data: {[number]: any}): ()
    local Type = GameEnum.KeyLookup(GameEnum.NotificationTypes, TypeEnum)
    local NewNotification = Assets.Lobby.Notifications:FindFirstChild(Type)

    if NewNotification then
        NewNotification = NewNotification:Clone() :: Frame & {UIScale: UIScale}

        if TypeEnum == GameEnum.NotificationTypes.PartyInvite then
            NewNotification.NotifText.Text = `{Data[2]} invited you to their party!`

            local IsDestroying = false;
            local function Destroy()
                if IsDestroying then return end;
                IsDestroying = true;

                NewNotification.JoinButton.Interactable = false;
                Effects:Tween(NewNotification.UIScale, {.25, 'Quad'}, {Scale = 0})

                Effects:CleanUp(NewNotification, 0.25)
            end

            NewNotification.QuitButton.MouseButton1Click:Once(function()
                RejectPartyInvite(Data[1] :: string)

                Destroy()
            end)
            NewNotification.JoinButton.MouseButton1Click:Once(function()
                AcceptPartyInvite(Data[1] :: string)
                Destroy()
            end)

            Effects:CleanUp(Destroy, Data[3])
        elseif TypeEnum == GameEnum.NotificationTypes.ObtainedCharacter then
            NewNotification.NotifText.Text = `You got: {Data[1]}`

            local IsDestroying = false;
            local function Destroy()
                if IsDestroying then return end;
                IsDestroying = true;

                Effects:Tween(NewNotification.UIScale, {.25, 'Quad'}, {Scale = 0})

                Effects:CleanUp(NewNotification, 0.25)
            end

            NewNotification.QuitButton.MouseButton1Click:Once(Destroy)

            Effects:CleanUp(Destroy, Data[2] or 3)
        end

        NewNotification.Parent = Notifications:GetFrame().List
    end
end

function Notifications:Init()
    Network:On("Notification", function(TypeEnum: number, Data: {})
        Notifications:Add(TypeEnum, Data)
    end)
end

return Notifications :: Types.UIComponent & {
    Add: (self: Types.UIComponent, TypeEnum: number, Data: {[string]: any}) -> (),
}
