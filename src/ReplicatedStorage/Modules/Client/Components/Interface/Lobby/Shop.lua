local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Products = require(Shared.Database.Products)
local UIEffects = require(Client.Utility.UIEffects)
local UIStates = require(Client.States.Interface)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)

local Component = ComponentClass.new("Shop", "Shop", {KeyToBind = Enum.KeyCode.P})

local function RequestBuyProduct(Type: string, Size: string)
    Network:Fire('Shop', GameEnum.MarketplaceRequestTypes.BuyProduct, {Type, Size})
end

--
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
        if UIStates:Get("MENU_TAB_OPEN") or UIStates:Get("SETTINGS_OPEN") then
            State = false
        end

        UIStates:Set('MENU_BLOCKED', not State)
        UIStates:Set('SHOP_OPEN', State)

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

    for _, Page in MainFrame.Shop.Pages:GetChildren() do
        if not Page:IsA('Frame') then continue end

        local PageType = string.gsub(Page.Name, 'Shop', '')
        local Options = Page:FindFirstChild('Options')

        for _, BuyOption in Options:GetChildren() do
            local Size = BuyOption.Name

            BuyOption.Button.MouseButton1Click:Connect(function()
                RequestBuyProduct(PageType, Size)

                BuyOption.UIScale.Scale = 0.8
                EffectUtil:Tween(BuyOption.UIScale, {.3, 'Back'}, {Scale = 1})
            end)
        end
    end

    --
    for _, Tab in MainFrame.Shop.TabList:GetChildren() do
        if not Tab:IsA('Frame') then continue end

        local TabPointer = Tab.TabObj.Value
        Tab.Button.MouseButton1Click:Connect(function()
            Pages.UIPageLayout:JumpTo(TabPointer)
        end)
    end

    UIEffects:AnimateReturnButton(MainFrame.Shop.Return, function()
        Component:Set(false)
    end)
end

function Component:OpenOn(Tab: string)
    local MainFrame = self:GetFrame()

    local Layout = MainFrame.Shop.Pages.UIPageLayout :: UIPageLayout
    local Page = MainFrame.Shop.Pages:FindFirstChild(Tab .. 'Shop')

    Layout:JumpTo(Page)

    Component:Set(true)
end

return Component