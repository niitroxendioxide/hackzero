local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Interface.Menu.Settings
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

-- interfaces
type BoolOption = Frame & {
    Btn: TextButton,
    SetName: TextLabel,
    Opt: Frame & {UICorner: UICorner, UIStroke: UIStroke, 
    Ball: Frame & {UIStroke: UIStroke, UIGradient: UIGradient}}
}

type SliderOption = Frame & {
    Slider: Frame & {
        Bar: Frame,
        Grab: Frame & {
            Btn: TextButton
        },
    },

    SetName: TextLabel,
    Value: TextLabel,
}

type OptButton = BoolOption & SliderOption

type CategoryList = ScrollingFrame & {
    UIListLayout: UIListLayout,
    UIPadding: UIPadding,
    
    [any]: OptButton,
}
type SettingsPage = Frame & {
    Backgrounds: Folder & {};
    Labels: Folder;
    Background: ImageLabel,
    Save: Frame & {
        UIStroke: UIStroke,
        UIScale: UIScale,
        Btn: TextButton,
    },

    [string]: CategoryList,
}

--
local AudioController = require(ReplicatedStorage.Modules.Client.Controllers.AudioController)
local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local ProfileTemplate = require(Shared.Database.Data.ProfileTemplate)

local Effects = require(Shared.Utility.Effects)
local Network = require(Shared.Network)
local Settings = require(Client.Packages.Settings)
local StringsUtil = require(Shared.Utility.String)

local AppearanceValues = {

    Bool = {
        ActiveColor = Color3.fromRGB(112, 255, 87);
        InactiveColor = Color3.fromRGB(255, 87, 87);
    }

};

--
local PageController = {}
local States = {
    MainFrame = nil :: SettingsPage,

    PreviousToUpdate = {}, 
    ChangedSettings = {},
    Changed = false,
}

function ChangeSettings(): ()
    Network:Fire("PlayerSettings", States.ChangedSettings)

    States.ChangedSettings = {};
    States.PreviousToUpdate = {};
    States.Changed = false;

    Effects:Tween(States.MainFrame.Save.UIScale, {.15, 'Back', 'In'}, {Scale = 0})
end

function ResetToDefaults(Category: string)
    if not ProfileTemplate.Settings[Category] then return end;

    for Key, State in ProfileTemplate.Settings[Category] do
        SwitchValue(State, Key, Category);
    end
end

function SetBoolDisplay(State: boolean, Name: string, Category: string)
    local ButtonObject: BoolOption = States.MainFrame[Category]:FindFirstChild(Name) :: BoolOption
    
    if ButtonObject then
        local Color = State and AppearanceValues.Bool.ActiveColor or AppearanceValues.Bool.InactiveColor
        local OrbPos = (not State) and UDim2.new(0, 2, 0.5, 0) or UDim2.new(.5, -2, 0.5, 0)
        local Darker = Color:Lerp(Color3.new(), 0.33)

        Effects:Tween(ButtonObject.Opt.Ball, {.2, 'Sine'},
        {Position = OrbPos})

        ButtonObject.Opt.Ball.BackgroundColor3 = Color
        ButtonObject.Opt.Ball.UIStroke.Color = Color
        ButtonObject.Opt.UIStroke.Color = Color
        ButtonObject.Opt.Ball.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Darker),
            ColorSequenceKeypoint.new(1, Color3.new(1,1, 1)),}
        ButtonObject.Opt.BackgroundColor3 = Color
    end
end

function SetSliderDisplay(Value: number, Key: string, Category: string)
    local ButtonObject: SliderOption = States.MainFrame[Category]:FindFirstChild(Key) :: SliderOption
    if not ButtonObject then
        return;
    end

    -- in case i wanna smooth it later
    local UdimAt = UDim2.fromScale(math.clamp(Value, 0, 1), 1)

    ButtonObject.Slider.Grab.Position = UdimAt
    ButtonObject.Slider.Bar.Size = UdimAt

    ButtonObject.Value.Text = tostring(math.floor(Value * 100)) .. "%"
end

function SwitchValue(NewValue: any, Key: string, Category: string)
    if typeof(NewValue) == 'boolean' then
        SetBoolDisplay(NewValue, Key, Category)
    elseif typeof(NewValue) == 'number' then
        SetSliderDisplay(NewValue, Key, Category)
    end
end

function HasOption(Key: string, Category: string): boolean
    if States.MainFrame:FindFirstChild(Category) and States.MainFrame[Category]:FindFirstChild(Key) then
        return true;
    end

    return false;
end

function EditSetting(Key: string, Category: string, Value: any, IgnoreChange: boolean?)
    if not States.ChangedSettings[Category] then
        States.ChangedSettings[Category] = {}
    end

    States.ChangedSettings[Category][Key] = Value;

    if string.match(Key, 'Volume') then
        local Type = string.split(Key, '_')[1]

        AudioController:EditVolume(Type, Value)
    end

    --
    SwitchValue(Value, Key, Category)

    if not States.Changed and not(IgnoreChange) then
        States.Changed = true                   
        
        Effects:Tween(States.MainFrame.Save.UIScale, {.15, 'Back'}, {Scale = 1})
    end
end

function CreateButton(Value: any, Name: string, List: CategoryList): ()
    local Category: string = List.Name;
    local Converted = StringsUtil:SplitTitleCaps(string.gsub(Name, "_", " ") :: string)

    if typeof(Value) == 'boolean' then
        local Button = Assets.Bool:Clone() :: BoolOption;
        Button.SetName.AutoLocalize = false;
        Button.SetName.Text = Converted;
        Button.Name = Name;
        Button.LayoutOrder = -2 
        Button.Parent = List;

        SetBoolDisplay(Value, Name, Category)
        Button.Btn.MouseButton1Click:Connect(function()
            local PreviousState = Settings:Get(Name, Category)
            Settings:Modify(Name, Category, not PreviousState)

            local CurrentState = Settings:Get(Name, Category)

            if not States.PreviousToUpdate[Category] then
                States.PreviousToUpdate[Category] = {}
            end

            if not States.PreviousToUpdate[Category][Name] then
                States.PreviousToUpdate[Category][Name] = PreviousState;
            end
            
            -- upd state & show
            EditSetting(Name, Category, CurrentState);
        end)
    elseif typeof(Value) == 'number' then
        local Order = Name == 'Master_Volume' and -1.1 or -1

        local Button = Assets.Slider:Clone() :: SliderOption;
        Button.SetName.AutoLocalize = false;
        Button.SetName.Text = Converted;
        Button.Name = Name;
        Button.LayoutOrder = Order
        Button.Parent = List;

        SetSliderDisplay(Value, Name, Category)

        Button.Slider.Grab.Btn.MouseButton1Down:Connect(function()
            local CurrentValue = Settings:Get(Name, Category) :: number;
            local Mouse = Players.LocalPlayer:GetMouse()

            while task.wait() do
                local MBDown = Inputs:IsMBDown(Enum.UserInputType.MouseButton1)
                if Inputs:IsDevice(GameEnum.Device.Desktop) and not MBDown then
                    break
                end

                local SliderValue = math.clamp((Mouse.X - Button.AbsolutePosition.X) / Button.AbsoluteSize.X, 0, 1)
                CurrentValue = SliderValue

                SetSliderDisplay(SliderValue, Name, Category)
            end

            EditSetting(Name, Category, CurrentValue);
        end)
    end
end

function PageController:Init(Frame: SettingsPage)
    States.MainFrame = Frame
    PageController:Refresh()

    -- // animate the save button
    Frame.Save.Visible = true;
    Frame.Save.UIScale.Scale = 0;

    Frame.Save.Btn.MouseButton1Click:Connect(ChangeSettings)

    Frame.Save.Btn.MouseEnter:Connect(function()
        Effects:Tween(Frame.Save, {.25}, {BackgroundColor3 = Color3.fromRGB(34, 218, 59)})
        Effects:Tween(Frame.Save.UIStroke, {.25, 'Sine'}, {Color = Color3.fromRGB(32, 204, 58)})
        Effects:Tween(Frame.Save.UIScale, {.15, 'Quad'}, {Scale = 1.1})
    end)

    Frame.Save.Btn.MouseLeave:Connect(function()
        Effects:Tween(Frame.Save, {.25, 'Sine'}, {BackgroundColor3 = Color3.fromRGB(18, 116, 32)})
        Effects:Tween(Frame.Save.UIStroke, {.25, 'Sine'}, {Color = Color3.fromRGB(16, 102, 30)})
        Effects:Tween(Frame.Save.UIScale, {.15, 'Quad'}, {Scale = States.Changed and 1 or 0})
    end)
end

function PageController:Refresh()
    local Frame: SettingsPage = States.MainFrame
    
    for _, Category in Settings:ListCategories() do
        if not( Frame:FindFirstChild(Category) ) then
            continue
        end
        
        for _, Option in Settings:ListOptions(Category) do
            local Value = Settings:Get(Option, Category)
            
            if HasOption(Option, Category) then
                EditSetting(Option, Category, Value, true)
            else
                CreateButton(Value, Option, Frame:FindFirstChild(Category) :: CategoryList)
            end
        end
    end
end

return PageController;