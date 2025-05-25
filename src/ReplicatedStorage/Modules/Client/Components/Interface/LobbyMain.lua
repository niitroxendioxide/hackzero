local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService("Lighting")
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local Types = require(Shared.Types)
local Statics = require(Shared.Database.Statics)
local UIGroups = require(Client.Libraries.UIGroups)
local UIEffects = require(Client.Utility.UIEffects)
local ComponentClass = require(Client.Classes.Interface)
local EffectUtil = require(Shared.Utility.Effects)
local Inputs = require(Client.Libraries.Inputs)
local LocalData = require(Client.Libraries.LocalData)
local IconDatabase = require(Shared.Database.Icons)

--
local Component = ComponentClass.new("MainMenu", 'Lobby') :: Types.UIComponent & Types.UIGetSetButton

local States = {
    Active = false,
}
local function ToggleTab(State: boolean)
    local MainFrame = Component:GetFrame()
    local Buttons = MainFrame.Buttons
    local Tab = MainFrame.MainButtonTab

    States.Active = State
    Buttons.Visible = not States.Active

    if State then
        local MenuCorr: ColorCorrectionEffect = Lighting:FindFirstChild("MenuCorrection") or Instance.new("ColorCorrectionEffect")
        MenuCorr.Name = "MenuCorrection"
        MenuCorr.Parent = Lighting


        local MenuBlur: BlurEffect = Lighting:FindFirstChild("MenuBlur") or Instance.new("BlurEffect")
        MenuBlur.Name = "MenuBlur"
        MenuBlur.Size = 0
        MenuBlur.Parent = Lighting

        EffectUtil:Tween(MenuBlur, {.3, 'Back'}, {Size = 16})
        EffectUtil:Tween(MenuCorr, {.225}, {
            Saturation = -1.3,
            Contrast = 0.25,
            Brightness = -0.05
        })

        EffectUtil:Tween(Tab, {.3, 'Cubic'}, {Position = UDim2.fromScale(1, 0)})
    else
        local MenuCorr: ColorCorrectionEffect = Lighting:FindFirstChild("MenuCorrection")
        local MenuBlur: BlurEffect = Lighting:FindFirstChild("MenuBlur")

        if MenuBlur then
            EffectUtil:Tween(MenuBlur, {.3, 'Quint'}, {Size = 0})
        end

        if MenuCorr then
            EffectUtil:Tween(MenuCorr, {.2, 'Sine'}, {Saturation = 0, Contrast = 0, Brightness = 0})
        end

        EffectUtil:Tween(Tab, {.25, 'Cubic', 'In'}, {Position = UDim2.fromScale(1.5, 0)})
    end

    --
end

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("MainMenu", true)

    return Main
end

function Component:GetButton(Name: string)
    local MainFrame = Component:GetFrame()

    local ButtonFolder = MainFrame:FindFirstChild("Buttons")

    return ButtonFolder:FindFirstChild(Name)
end

function Component:SetButton(Name: string)
    -- empty
end

function Component:CreateTabButton(Name: string)
    local MainFrame = Component:GetFrame()
    local Tab = MainFrame.MainButtonTab
    local Id = IconDatabase.Buttons[Name]

    local ButtonObj = Assets.Interface.Lobby.Main.MenuButton:Clone()
    ButtonObj.TabName.Text = Name
    ButtonObj.Icon.IconImg.Image = 'rbxassetid://' .. Id
    ButtonObj.Parent = Tab.Buttons
    ButtonObj.Name = Name

    --
    local Icon: Frame & {UIScale: UIScale, IconImg: ImageLabel, UIStroke: UIStroke} = ButtonObj.Icon
    local Selector: TextButton = ButtonObj.Button

    Selector.MouseButton1Click:Connect(function()
        local Element = UIGroups:GetElementClass("Lobby", Name)

        if not Element then return end
        ToggleTab(false)

        Element:Set(true)
    end)

    local Tween: Tween = nil;
    local Thread: thread = nil;
    Selector.MouseEnter:Connect(function()
        if Tween then
            Tween:Cancel()
            Tween:Destroy()
        end

        if Thread then
            task.cancel(Thread)
        end

        Icon.UIStroke.Thickness = 2
        Icon.UIStroke.Transparency = 0.15
        ButtonObj.UIStroke.Color = Color3.new(1, 1, 1)

        Thread = task.spawn(function()
            local Angle = 0

            while true do
                local Delta = task.wait()

                Angle += Delta * 180
                Icon.UIStroke.Thickness = 2 + math.sin(math.rad(Angle))
                ButtonObj.UIStroke.Thickness = 1 + math.sin(math.rad(Angle)) * .5
            end
        end)


        EffectUtil:Tween(ButtonObj.UIScale, {.2, 'Back'}, {Scale = 1.1})
        Tween = EffectUtil:Tween(Icon.UIScale, {.25, 'Cubic'}, {Scale = 1.25})
        EffectUtil:Tween(Icon, {.25, 'Cubic'}, {Rotation = -5})
    end)

    Selector.MouseLeave:Connect(function()
        if Tween then
            Tween:Cancel()
            Tween:Destroy()
        end

        if Thread then
            task.cancel(Thread)
        end

        Icon.UIStroke.Thickness = 1
        Icon.UIStroke.Transparency = 0.854
        ButtonObj.UIStroke.Color = Color3.new()
        ButtonObj.UIStroke.Thickness = 1

        EffectUtil:Tween(ButtonObj.UIScale, {.2, 'Quad'}, {Scale = 1})
        EffectUtil:Tween(Icon, {.25, 'Cubic'}, {Rotation = 0})
        Tween = EffectUtil:Tween(Icon.UIScale, {.25, 'Cubic'}, {Scale = 1})
    end)
end

function Component:ShowCurrency(Name: string)
    --
    local Currencies = LocalData:GetCurrencies() or {}
    local Amount = Currencies[Name] or 0
    local MainFrame = Component:GetFrame()
    local CurrencyFrame = MainFrame.Currencies

    local OldFrame = CurrencyFrame.List:FindFirstChild(Name)
    if OldFrame then
        OldFrame.CurrencyVal.Text = tostring(Amount)
        return
    end

    local NewObject = Assets.Interface.Lobby.Main.Currency:Clone()
    NewObject.Name = Name
    NewObject.CurrencyVal.Text = Amount
    NewObject.Icon.Image = 'rbxassetid://' .. (IconDatabase.Currency[Name] or 0)
    NewObject.Parent = CurrencyFrame.List

    NewObject.Button.MouseButton1Click:Connect(function()
        print("gotta buy", Name)
    end)

    NewObject.Button.MouseEnter:Connect(function()
        EffectUtil:Tween(NewObject.Buy.UIScale, {.25, 'Cubic'}, {Scale = 1})
    end)

    NewObject.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(NewObject.Buy.UIScale, {.25, 'Cubic'}, {Scale = 0})
    end)
end

function Component:Init(): ()
    local MainFrame = Component:GetFrame()
    local MainTab = MainFrame.MainButtonTab

    --
    MainTab.VersionLabel.Text = 'v' .. Statics.GameVersion
    MainTab.UserIdLabel.Text = Player.UserId

    --
    for _, ButtonName in {'Inventory', 'Agents', 'Settings', 'Map'} do
        Component:CreateTabButton(ButtonName)
    end

    for _, ButtonName in {'Money', 'Gems'} do
        Component:ShowCurrency(ButtonName)
    end

    Component:BindToStateChange(function(State: boolean)
        if State then
            UIEffects:Transition("Lobby", .75)

            MainFrame.Buttons.Visible = true
        end
    end)

    Component:Set(true)

    -- Menu btn
    local Menu = Component:GetButton("Menu")
    Menu.Button.MouseButton1Click:Connect(function()
        ToggleTab(not States.Active)
    end)

    Menu.Button.MouseEnter:Connect(function()
        Menu.UIStroke.Color = Color3.new(1, 1, 1)

        EffectUtil:Tween(Menu.Icon.UIScale, {.2}, {Scale = 1.1})
    end)

    Menu.Button.MouseLeave:Connect(function()
        Menu.UIStroke.Color = Color3.new()

        EffectUtil:Tween(Menu.Icon.UIScale, {.2}, {Scale = 1})
    end)

    --
    local Agents = Component:GetButton("Agents")
    Agents.Button.MouseButton1Click:Connect(function()
        local Element = UIGroups:GetElementClass("Lobby", 'Agents')
        if not Element then return end

        ToggleTab(false)
        Element:Set(true)
    end)

    Agents.Button.MouseEnter:Connect(function()
        Agents.UIStroke.Color = Color3.new(1, 1, 1)

        EffectUtil:Tween(Agents.Icon.UIScale, {.2}, {Scale = 1.1})
    end)

    Agents.Button.MouseLeave:Connect(function()
        Agents.UIStroke.Color = Color3.new()

        EffectUtil:Tween(Agents.Icon.UIScale, {.2}, {Scale = 1})
    end)

    --
    UIEffects:AnimateReturnButton(MainTab.Return, function()
        ToggleTab(false)
    end)

    --

    --
    Inputs:Bind(Enum.KeyCode.M, {
        Callback = function()
            if UIGroups:GetActiveElement("Lobby") ~= Component then
                ToggleTab(false)

                return
            end

            ToggleTab(not States.Active)
        end
    })
end

function Component:IsMenuOpen()
    return States.Active
end

return Component