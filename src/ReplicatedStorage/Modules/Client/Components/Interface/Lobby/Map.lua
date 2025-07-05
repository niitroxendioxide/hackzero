local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local UIGroups = require(Client.Libraries.UIGroups)
local UIEffects = require(Client.Utility.UIEffects)
local ComponentClass = require(Client.Classes.Interface)

--
local Component = ComponentClass.new("Map", 'Lobby') :: Types.UIComponent & Types.UIGetSetButton

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Maps", true)

    return Main
end

function Component:BindToPlace(Opt: string, Callback: () -> ())
    local Frame = Component:GetFrame()
    local Buttons = (Frame:FindFirstChild('Pop') :: Frame):FindFirstChild('Buttons') :: Folder
    local ButtonFrame = Buttons:FindFirstChild(Opt) :: Frame & {Btn: TextButton}

    ButtonFrame.Btn.MouseButton1Click:Connect(Callback)

    return;
end

function Component:Init()
    local MainFrame = Component:GetFrame()
    local Pop = MainFrame:FindFirstChild("Pop") :: Frame & {Return: Frame}
    if not Pop then
        return
    end

    UIEffects:AnimateReturnButton(Pop.Return, function(...: any)
        Component:Set(false)

        local Lobby = UIGroups:GetElementClass("Lobby", "MainMenu")
        Lobby:Set(true, true)
    end)

    Component:BindToPlace("AFK", function()
        Network:Fire("AFKEvent", 2)
    end)
end

return Component