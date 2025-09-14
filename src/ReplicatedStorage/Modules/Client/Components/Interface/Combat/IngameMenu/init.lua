local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local UIGroups = require(ReplicatedStorage.Modules.Client.Libraries.UIGroups)
local ComponentClass = require(Client.Classes.Interface)
local UIStates = require(Client.States.Interface)
local EffectUtil = require(Shared.Utility.Effects)

local IngameMenu = ComponentClass.new("IngameMenu", "MenuGui", {KeyToBind = Enum.KeyCode.M})
local States = {
    CachedTabs = {},
    CurrentPage = "",
}

local BLACK = Color3.new()
local WHITE = Color3.new(1, 1, 1)

function IngameMenu:Link(Player: Player)
    local Gui = Player.PlayerGui
    if not (Gui:WaitForChild("FullScreenHUD", 10)) then
        return;
    end

    return Gui.FullScreenHUD.Screen.Menu
end

function IngameMenu:Init()

    local Holder = IngameMenu:GetFrame()
    local MainFrame = IngameMenu:GetFrame().Main;
    local PageLayout: UIPageLayout = MainFrame.Pages.UIPageLayout

    for _, PageController in script:GetChildren() do
        if PageController:IsA("ModuleScript") and MainFrame.Pages:FindFirstChild(PageController.Name) then
            local Success, RequiredModule = pcall(require, PageController)
            if not Success or typeof(RequiredModule) ~= 'table' then
                continue
            end

            if RequiredModule.Init then
                task.spawn(RequiredModule.Init, RequiredModule, MainFrame.Pages[PageController.Name])
            end

            States.CachedTabs[PageController.Name] = RequiredModule;
        end
    end

    local function SelectButton(Name: string)
        if (States.CurrentPage ~= Name) then
            local OtherButton = MainFrame.OptList:FindFirstChild(States.CurrentPage)
            if OtherButton then
                EffectUtil:Tween(OtherButton.UIScale, {.25, 'Back'}, {Scale = 1})
                EffectUtil:Tween(OtherButton, {.2, 'Sine'}, {BackgroundColor3 = BLACK})
                EffectUtil:Tween(OtherButton.UIStroke, {.3, 'Cubic'}, {Color = BLACK})
                EffectUtil:Tween(OtherButton.Background, {.25, 'Quint'}, {ImageColor3 = Color3.fromRGB(30, 30, 30)})
            end

        else
            return
        end

        --
        local Button = MainFrame.OptList[Name]
        States.CurrentPage = Button.Name

        EffectUtil:Tween(Button.UIScale, {.25, 'Back'}, {Scale = 1.1})
        EffectUtil:Tween(Button, {.3, 'Cubic'}, {BackgroundColor3 = WHITE})
        EffectUtil:Tween(Button.UIStroke, {.3, 'Cubic'}, {Color = WHITE})
        EffectUtil:Tween(Button.Background, {.25, 'Cubic'}, {ImageColor3 = WHITE})
    end

    for _, Button in MainFrame.OptList:GetChildren() do
        if Button:IsA("Frame") then
            local Btnobj = (Button.Btn :: TextButton)
            Btnobj.MouseButton1Click:Connect(function()
                local PageName = Button.Name .. 'Page'
                PageLayout:JumpTo(MainFrame.Pages[PageName])
            end)
        end
    end

    PageLayout.PageEnter:Connect(function(PageObj)
        local WNoPage = string.gsub(PageObj.Name, "Page", "")
        if typeof(States.CachedTabs[PageObj.Name].Refresh) == 'function' then
            States.CachedTabs[PageObj.Name]:Refresh()
        end

        SelectButton(WNoPage)
    end)

    IngameMenu:BindToStateChange(function(State: boolean)
        Holder.Visible = true
        UIStates:Set("MainMenu", State)

        if (UIGroups:IsActive("END", "EndScreen")) then
            State = false
        end

        if State then
            if States.CurrentPage == nil or #States.CurrentPage <= 0 then
                SelectButton('Party')
                States.CachedTabs['PartyPage']:Refresh()
            end

            EffectUtil:Tween(Holder, {.25}, {BackgroundTransparency = 0.45})
            EffectUtil:Tween(Holder.Bg, {.4,'Sine'}, {ImageTransparency = 0.85})
            EffectUtil:Tween(MainFrame, {.3, 'Back'}, {Position = UDim2.fromScale(0.5, 0.5)})
        else
            EffectUtil:Tween(MainFrame, {.3, 'Back', 'In'}, {Position = UDim2.fromScale(0.5, 1.5)})
            EffectUtil:Tween(Holder, {.25}, {BackgroundTransparency = 1})
            EffectUtil:Tween(Holder.Bg, {.4, 'Sine'}, {ImageTransparency = 1})
        end

    end)

end

return IngameMenu
