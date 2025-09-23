local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Interface.Menu.Settings
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

-- interfaces
type BoolOption = Frame & {
    Btn: TextButton,
    SetName: TextLabel,
    Opt: Frame & {UICorner: UICorner, UIStroke: UIStroke, Ball: Frame}
}

type SliderOption = Frame & {}

type OptButton = BoolOption | SliderOption

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
        Btn: TextButton,
    },

    [string]: CategoryList,
}

--
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
    MainFrame = nil :: SettingsPage?,

    PreviousToUpdate = {},
    ChangedSettings = {},
}

function ChangeSettings(): ()
    Network:Fire("PlayerSettings", States.ChangedSettings)

    States.ChangedSettings = {};
    States.PreviousToUpdate = {};

    States.MainFrame.Save.Visible = false;
end

function ResetToDefaults(Category: string)

end

function SetBoolDisplay(State: boolean, Name: string, Category: string)
    local ButtonObject = States.MainFrame[Category]:FindFirstChild(Name) :: BoolOption
    
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

function EditSetting(Key: string, Category: string, Value: any)
    if not States.ChangedSettings[Category] then
        States.ChangedSettings[Category] = {}
    end

    States.ChangedSettings[Category][Key] = Value;

    --
    States.MainFrame.Save.Visible = true;
end

function CreateButton(Value: any, Name: string, List: CategoryList): ()
    local Category = List.Name;

    if typeof(Value) == 'boolean' then
        local Converted = string.gsub(Name, "_", " ")
        local Button = Assets.Bool:Clone() :: BoolOption;
        Button.SetName.AutoLocalize = false;
        Button.SetName.Text = StringsUtil:SplitTitleCaps(Converted);
        Button.Name = Name;

        local CurrentState: boolean = Value;
        Button.Btn.MouseButton1Click:Connect(function()
            if not States.PreviousToUpdate[Category] then
                States.PreviousToUpdate[Category] = {}
            end

            if not States.PreviousToUpdate[Category][Name] then
                States.PreviousToUpdate[Category][Name] = CurrentState;
            end

            -- upd state & show
            CurrentState = not CurrentState;
            SetBoolDisplay(CurrentState, Name, Category);
            EditSetting(Name, Category, CurrentState);
        end)

        SetBoolDisplay(CurrentState, Name, Category)

        Button.Parent = List;
    end
end

function PageController:Init(Frame: SettingsPage)
    States.MainFrame = Frame;

    Frame.Save.Btn.MouseButton1Click:Connect(ChangeSettings)

    for _, Category in Settings:ListCategories() do
        if not( Frame:FindFirstChild(Category) ) then
            continue
        end

        for _, Option in Settings:ListOptions(Category) do
            local Value = Settings:Get(Option, Category)
            
            CreateButton(Value, Option, Frame:FindFirstChild(Category) :: CategoryList)
        end
    end
end

return PageController;