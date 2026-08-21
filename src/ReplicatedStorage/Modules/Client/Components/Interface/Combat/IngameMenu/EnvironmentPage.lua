local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

const PAGE_ENABLED = false
local Environment = require(Shared.Environment);

type BaseInterface = Frame & {
    Leave: Frame & {Btn: TextButton, UIScale: UIScale},
    Background: ImageLabel,
    Title: TextLabel,
}

--
local PageController = {
    Frame = nil :: BaseInterface?,
}

local function RecolorOnType(TextBox: TextBox, Value: any)
    local LowerCaseMatch = string.lower(TextBox.Text)
    if LowerCaseMatch == 'false' and typeof(Value) == 'boolean' then
        TextBox.TextColor3 = Color3.new(1, 0, 0)
    elseif LowerCaseMatch == 'true' and typeof(Value) == 'boolean' then
        TextBox.TextColor3 = Color3.fromRGB(7, 255, 15)
    elseif typeof(Value) == 'string' then
        TextBox.TextColor3 = Color3.fromRGB(202, 255, 153)
    elseif typeof(Value) == 'number' then
        TextBox.TextColor3 = Color3.fromRGB(255, 202, 80)
    end
end

function PageController:Init(Frame: BaseInterface)
    PageController.Frame = Frame

    ---
    if not PAGE_ENABLED and not RunService:IsStudio() then
        return
    end
    
    PageController.Frame.Visible = true

    ---
    for Name, ValueType in Environment do
        local NewItem = Assets.Interface.Menu.EnvironmentItem:Clone()
        NewItem.Parent = Frame.List;
        NewItem.Label.Text = Name;
        NewItem.Value.Text = tostring(ValueType);
        RecolorOnType(NewItem.Value, ValueType)

        NewItem.Value.FocusLost:Connect(function(EnterPressed: boolean)
            local New_Input = NewItem.Value.Text 
            local LowerCaseMatch = string.lower(New_Input)

            if (LowerCaseMatch == 'true' or LowerCaseMatch == 'false') and typeof(ValueType) == 'boolean' then
                local CorrectedValue = (LowerCaseMatch == 'true')
                Environment[Name] = CorrectedValue;
                
                NewItem.Value.Text = LowerCaseMatch;
            elseif typeof(ValueType) == 'string' then
                Environment[Name] = New_Input
                NewItem.Value.Text = New_Input;
            elseif typeof(ValueType) == 'number' then
                local NumValue = tonumber(New_Input, 10)
                if not NumValue then
                    return;
                end

                Environment[Name] = NumValue
                NewItem.Value.Text = New_Input;
            end

            
            RecolorOnType(NewItem.Value, ValueType)
        end)
    end
end

function PageController:Refresh()
    --
end

return PageController;