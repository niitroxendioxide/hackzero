local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Products = require(Shared.Database.Products)
local UIStates = require(Client.States.Interface)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)

local Component = ComponentClass.new("Shop", "Shop", {KeyToBind = Enum.KeyCode.P})

function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("Shop", true)

	return Main;
end

function Component:Init()
    local MainFrame = self:GetFrame()
    local Pages = MainFrame.Shop.Pages

    Component:BindToStateChange(function(State: boolean)
        MainFrame.Visible = true
        if UIStates:Get("MENU_TAB_OPEN") then
            State = false
        end

        UIStates:Set('MENU_BLOCKED', not State)

        if State then
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 0.3})
            EffectUtil:Tween(MainFrame.Shop.UIScale, {.3, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Shop, {.1, 'Circular'}, {Position = UDim2.fromScale(0.524, .5)})
        else
            EffectUtil:Tween(MainFrame.Shop.UIScale, {.3, 'Quad', 'In'}, {Scale = 0})
            EffectUtil:Tween(MainFrame.Shop, {.1, 'Circular'}, {Position = UDim2.fromScale(0.524, -.25)})
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 1})
        end
    end)

    self:Set(false)

    --
    for _, Tab in MainFrame.Shop.TabList:GetChildren() do
        if not Tab:IsA('Frame') then continue end

        local TabPointer = Tab.TabObj.Value
        Tab.Button.MouseButton1Click:Connect(function()
            Pages.UIPageLayout:JumpTo(TabPointer)
        end)
    end
end

return Component