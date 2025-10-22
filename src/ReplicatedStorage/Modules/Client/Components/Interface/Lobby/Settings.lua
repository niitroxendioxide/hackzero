local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Assets = ReplicatedStorage.Assets
local Player = Players.LocalPlayer

--
local ComponentClass = require(Client.Classes.Interface)
local EffectUtil = require(Shared.Utility.Effects)
local UIStates = require(Client.States.Interface)
local Settings = require(Client.Packages.Settings)
local UIEffects = require(Client.Utility.UIEffects)
local StringUtil = require(Shared.Utility.String)

local Component = ComponentClass.new("Settings", "Settings");
local States = {
    Selected = nil,
}

-- Private functions
function HighlightOption(Holder, SelectedOption)
    if States.Selected == SelectedOption.Name then
        return
    end

    States.Selected = SelectedOption.Name

    local Info = {.4, 'Cubic'}
    for _, Option in Holder:GetChildren() do
        if not Option:IsA("Frame") then continue end

        if Option == SelectedOption then
            EffectUtil:Tween(Option.Design.UIScale, {.3, 'Back'}, {Scale = 1})
            EffectUtil:Tween(Option.Design, Info, {BackgroundTransparency = 0.85})
            EffectUtil:Tween(Option.Design.UIStroke, Info, {Transparency = 0.5})
        else
            EffectUtil:Tween(Option.Design.UIScale, {.3, 'Back'}, {Scale = 0.9})
            EffectUtil:Tween(Option.Design, Info, {BackgroundTransparency = 0.95})
            EffectUtil:Tween(Option.Design.UIStroke, Info, {Transparency = 0.85})
        end
    end
end

function ToggleSetting(Category: string, Key: string, Holder: Instance)
    local SettingObj = Assets.Interface.Lobby.Settings.Setting:Clone()
    local Toggle = Assets.Interface.Lobby.Settings.ToggleButton:Clone()

    local SettingCorrectedName = string.gsub(Key, "_", " ")
    SettingObj.SettingName.Label.Text = StringUtil:SplitTitleCaps(SettingCorrectedName)
    SettingObj.Name = Key;
    SettingObj.Parent = Holder
    Toggle.Parent = SettingObj;    
    Toggle.Button.MouseButton1Click:Connect(function()
        Settings:Modify(Key, Category, not Settings:Get(Key, Category))
        DisplayValue(Category, Key, Settings:Get(Key, Category));
    end)

    DisplayValue(Category, Key, Settings:Get(Key, Category));
end

function DisplayValue(Category: string, Key: string, State: any)
    local MainFrame = Component:GetFrame()
    local Opts = MainFrame.Settings.Options
    local SettingObj = Opts:FindFirstChild(Category) and Opts[Category].List:FindFirstChild(Key)
    
    if typeof(State) == 'boolean' and SettingObj then
        local Icon = SettingObj.ToggleButton.Toggle.Icon;

        if State then
            EffectUtil:Tween(Icon.UIStroke, {1 / 3, 'Cubic'}, {Color = Color3.fromRGB(130, 255, 47)})
            EffectUtil:Tween(Icon, {1 / 3, 'Cubic'}, {BackgroundColor3 = Color3.fromRGB(79, 182, 0)})
            EffectUtil:Tween(Icon, {.2, 'Sine'}, {Position = UDim2.fromScale(0.775, .5)})
        else
            EffectUtil:Tween(Icon.UIStroke, {1 / 3, 'Cubic'}, {Color = Color3.fromRGB(255, 47, 47)})
            EffectUtil:Tween(Icon, {1 / 3, 'Cubic'}, {BackgroundColor3 = Color3.fromRGB(182, 0, 0)})
            EffectUtil:Tween(Icon, {.2, 'Sine'}, {Position = UDim2.fromScale(0.33, .5)})
        end
    end
end

--
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Settings", true)

    return Main
end

function Component:Init()
    local MainFrame = self:GetFrame()

    Component:BindToStateChange(function(State: boolean)
        MainFrame.Visible = true
        if UIStates:Get("MENU_TAB_OPEN") or UIStates:Get("SHOP_OPEN") then
            State = false
        end

        UIStates:Set('MENU_BLOCKED', not State)
        UIStates:Set('SETTINGS_OPEN', State)

        if State then
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 0.3})
            EffectUtil:Tween(MainFrame.Settings.UIScale, {.3, 'Back'}, {Scale = 1})
            EffectUtil:Tween(MainFrame.Settings, {.1, 'Circular'}, {Position = UDim2.fromScale(0.524, .5)})
        else
            EffectUtil:Tween(MainFrame.Settings.UIScale, {.3, 'Quad', 'In'}, {Scale = 0})
            EffectUtil:Tween(MainFrame.Settings, {.1, 'Circular'}, {Position = UDim2.fromScale(0.524, .5)})
            EffectUtil:Tween(MainFrame.Background, {.25, 'Sine'}, {Transparency = 1})
        end
    end)

    local PageLayout = MainFrame.Settings.Options.UIPageLayout
    for _, Key in Settings:ListCategories() do
        local Name = (Key == 'QOL' and ('Accessibility') or Key) .. ' Settings'

        local TabHolder = Assets.Interface.Lobby.Settings.Tab:Clone()
        TabHolder.Name = Key
        TabHolder.Parent = MainFrame.Settings.Options

        local TabSideButton = Assets.Interface.Lobby.Settings.OptList:Clone()
        TabSideButton.Name = Key
        TabSideButton.TabObj.Value = TabHolder
        TabSideButton.Design.SettingTitle.Text = Name
        TabSideButton.Parent = MainFrame.Settings.TabList

        TabSideButton.Button.MouseButton1Click:Connect(function()
            PageLayout:JumpTo(TabHolder)

            HighlightOption(MainFrame.Settings.TabList, TabSideButton)
        end)

        for _, SettingName in Settings:ListOptions(Key) do
            local SettingValue = Settings:Get(SettingName, Key)
            if typeof(SettingValue) == 'boolean' then
                ToggleSetting(Key, SettingName, TabHolder.List)
            end
        end
    end

    local Tabs = MainFrame.Settings.TabList:GetChildren()
    table.remove(Tabs, table.find(Tabs, MainFrame.Settings.TabList.UIListLayout))

    local RandomTab = Tabs[math.random(1, #Tabs)]
    HighlightOption(MainFrame.Settings.TabList, RandomTab)

    PageLayout:JumpTo(RandomTab.TabObj.Value)

    UIEffects:AnimateReturnButton(MainFrame.Settings.Return, function()
        Component:Set(false)
    end)

    Component:Set(false)
end

function Component:Refresh()
    for _, Cat in Settings:ListCategories() do
        for _, Key in Settings:ListOptions(Cat) do
            DisplayValue(Cat, Key, Settings:Get(Key, Cat));
        end
    end
end

return Component