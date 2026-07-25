local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Assets = ReplicatedStorage:FindFirstChild("Assets")

local Types = require(Shared.Types.Assets)
local Inputs = require(Client.Libraries.Inputs)
local EffectUtil = require(Shared.Utility.Effects)
local IconDatabase = require(Database.Icons)
local ComponentClass = require(Client.Classes.Interface)
local AgentsLib = require(Client.Libraries.Characters)
local InterfaceStates = require(Client.Packages.InterfaceStates)

--
local FramePositions: {[string]: UDim2} = {
    Basic_Attack = UDim2.fromScale(0.857, 0.842),
    Dodge = UDim2.fromScale(0.777, 0.842),
    Swap_Forth = UDim2.fromScale(0.938, 0.842),
    Special = UDim2.fromScale(0.938, .625),
    Ultimate = UDim2.fromScale(0.857, .625)
}

local FrameScales: {[string]: number} = {
    Basic_Attack = 1,
    Dodge = .85,
    Swap_Forth = .85,
    Special = 1,
    Ultimate = 1,
}

--
local LastCoefficient = 0
local Thread = nil
local Component = ComponentClass.new("AFK", "AFK")

-- Privates
-- Convert a key name into its correct shown key
local function FixKeyName(Key: string): string
    if string.match(Key, 'MouseButton') then
        return 'MB'..string.sub(Key, #Key, #Key)
    end

    return Key
end

local function RefreshUltimateIcon(AgentName: string)
    local UltIcons = IconDatabase.Skills.Ultimates
    local AgentUltIcon = UltIcons[AgentName]

    local ObjectInFrame = Component:GetFrame().Buttons:FindFirstChild('Ultimate')
    if not (ObjectInFrame) or not (AgentUltIcon) then return end

    ObjectInFrame.Icon.Image = IconDatabase.PREFIX .. AgentUltIcon.Id
end

local function SetupKey(Object: Frame)
    local SkillNameType = Object.Name
    local KeyBinding = Inputs:GetEnumFromKey(SkillNameType)
    if not KeyBinding then return end

    local KeyEnum = (typeof(KeyBinding) == 'table' and KeyBinding[#KeyBinding] or KeyBinding) :: EnumItem
    local KeyName = FixKeyName(KeyEnum.Name)
    local KeyIcon = IconDatabase.Keybinds[KeyEnum]
    Object.Key.BG.KeyText.Text = string.gsub(KeyName, 'Button', '');

    if KeyIcon then
        Object.Key.BG.KeyText.Visible = false
    Object.Key.Icon.Visible = true
        Object.Key.Icon.Image = IconDatabase.PREFIX .. KeyIcon
    else
        --Object.Key.BG.Size = UDim2.fromScale(KeySize, 0.3)
        Object.Key.Icon.Visible = false
    end
end

-- Create the skill object on screen
local function CreateSkillObject(Name: string)
    if not FramePositions[Name] then
        return
    end

    local MainFrame = Component:GetFrame()
    local KeyBinding = Inputs:GetEnumFromKey(Name)
    if not KeyBinding then return end

    local InterfaceFolder = Assets:FindFirstChild('Interface') :: Types.GenericFolderContainer<Types.FrameButtonStructure>
    local ObjName = InterfaceFolder.Combat.Skill:FindFirstChild(Name == 'Ultimate' and 'UltFrame' or 'SkillFrame')
    if not ObjName then return end

    local Object = ObjName:Clone() :: Types.FrameButtonStructure
    --local KeySize = 0.48 + (0.0667 * #KeyName)

    local Icon = (IconDatabase.Skills[Name] or 0)

    Object.Name = Name
    Object.UIScale.Scale = FrameScales[Name] or 1
    Object.Icon.Image = IconDatabase.PREFIX .. Icon
    SetupKey(Object)
    Object.Position = FramePositions[Name]
    Object.Parent = MainFrame.Buttons
    Object:SetAttribute('Active', true)

    if Name == 'Ultimate' then
        local CurrentAgentName = AgentsLib:GetCurrentName(Player:GetAttribute('ReplicationId') :: number)

        RefreshUltimateIcon(CurrentAgentName)

        task.spawn(function()
            local Angle = 0;
            while true do
                local Delta = task.wait()
                Angle += Delta * math.pi*0.5

                Object.Meter.Fill.Rotation = math.sin(Angle) * 7
            end
        end)
    end
end

local function Press(ButtonName: string)
    if not FrameScales[ButtonName] then return end
    local MainFrame = Component:GetFrame()
    local ButtonObj = MainFrame.Buttons:FindFirstChild(ButtonName)
    if not ButtonObj:GetAttribute('Active') then return end

    EffectUtil:Tween(ButtonObj.UIScale, {.25, 'Cubic'}, {Scale = FrameScales[ButtonName] * 0.8})
end

local function Release(ButtonName: string)
    if not FrameScales[ButtonName] then return end

    local MainFrame = Component:GetFrame()
    local ButtonObj = MainFrame.Buttons:FindFirstChild(ButtonName)
    if not ButtonObj:GetAttribute('Active') then return end

    EffectUtil:Tween(ButtonObj.UIScale, {.25, 'Back'}, {Scale = FrameScales[ButtonName]})
end

local function SetUltBarFill(Coefficient: number)
    local MainFrame = Component:GetFrame()
    local UltBar = MainFrame.Buttons:FindFirstChild('Ultimate')
    local CurrentAgent = AgentsLib:GetCurrentName(Player:GetAttribute("ReplicationId"))
    local HasData = IconDatabase.Skills.Ultimates[CurrentAgent]
    if not(UltBar) then
        return
    end

    if not(HasData) then
        return
    end

    local Color = HasData.Color
    local FillStroke = UltBar.Inner.UIStroke
    local Offset = Vector2.new(0, 0.5 - Coefficient)

    if Thread then
        task.cancel(Thread)
    end

    EffectUtil:Tween(FillStroke.UIGradient, {.2, 'Sine'}, {Offset = Offset})
    EffectUtil:Tween(UltBar.Meter.Fill, {.2, 'Sine'}, {Size = UDim2.fromScale(1.25, 0.1 + Coefficient)})
    EffectUtil:Tween(UltBar.Meter.Fill, {.2}, {BackgroundColor3 = Color})
    UltBar.Meter.Fill.UIStroke.Color = Color
    FillStroke.UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.499, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color),
        ColorSequenceKeypoint.new(1,Color),
    }

    if LastCoefficient ~= Coefficient and Coefficient == 1 then
        local H = Color:ToHSV()
        local Rotated = H - 25
        if Rotated < 0 then Rotated += 360 end

        UltBar.Meter.Fill.UIStroke.Enabled = false
        EffectUtil:Tween(UltBar.UIStroke, {.3}, {Color = Color})
        UltBar.UIStroke.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromHSV(Rotated/360, 50/255, 200/255)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }

        UltBar.UIScale.Scale = .8
        EffectUtil:Tween(UltBar.UIScale, {.25, 'Back'}, {Scale = FrameScales.Ultimate})
        UltBar.UICorner.CornerRadius = UDim.new(.3, 0)
        EffectUtil:Tween(UltBar.UICorner, {.3, 'Back'}, {CornerRadius = UDim.new(.5)})

        Thread = task.spawn(function()
            local Angle = 0
            local Rotation = 0
            local Grad = UltBar.UIStroke.UIGradient
            while true do
                local Delta = task.wait()

                UltBar.UIStroke.Thickness = 0.08 + math.cos(math.rad(Angle)) * 0.02
                Angle += Delta * 280
                Rotation += Delta * 133
                Grad.Rotation = Rotation
            end
        end)
    elseif Coefficient < 1 then
        UltBar.Meter.Fill.UIStroke.Enabled = true
        EffectUtil:Tween(UltBar.UIStroke, {.3}, {Thickness = 0.05, Color = Color3.new()})
    end

    LastCoefficient = Coefficient
end

local function ToggleButton(Name: string, State: boolean)
    local MainFrame = Component:GetFrame()
    local SkillButton = MainFrame.Buttons:FindFirstChild(Name)
    if not SkillButton then return end
    SkillButton:SetAttribute('Active', State)

    if State == false then
        EffectUtil:Tween(SkillButton.Background, {.15}, {ImageTransparency = 1})
        EffectUtil:Tween(SkillButton.Icon, {.15}, {ImageTransparency = 1})
        EffectUtil:Tween(SkillButton.Cooldown, {.15}, {GroupTransparency = 1})
        EffectUtil:Tween(SkillButton.Key, {.15}, {GroupTransparency = 1})
        EffectUtil:Tween(SkillButton.Inner.UIStroke, {.15}, {Transparency = 1})
        EffectUtil:Tween(SkillButton.UIScale, {.15}, {Scale = 0.5})
    else
        EffectUtil:Tween(SkillButton.Background, {.15}, {ImageTransparency = 0.8})
        EffectUtil:Tween(SkillButton.Icon, {.15}, {ImageTransparency = 0})
        EffectUtil:Tween(SkillButton.Cooldown, {.15}, {GroupTransparency = 0})
        EffectUtil:Tween(SkillButton.Key, {.15}, {GroupTransparency = 0})
        EffectUtil:Tween(SkillButton.Inner.UIStroke, {.15}, {Transparency = .75})
        EffectUtil:Tween(SkillButton.UIScale, {.15}, {Scale = FrameScales[Name]})
    end
end

local function PopUpAgentIcon(Name: string)
    local MainFrame = Component:GetFrame()
    local AgentModel = Assets.Characters.Agents:FindFirstChild(Name)
    if not AgentModel then
        return
    end

    Component:DeletePopUp()

    --
    ToggleButton("Swap_Forth", false)

    local UiObject = Assets.Interface.Combat.Skill.AgentPopUp:Clone()
    UiObject.GroupTransparency = 1
    UiObject.Position = FramePositions.Swap_Forth
    UiObject.UIStroke.Transparency = 1
    UiObject.UIScale.Scale = 1.1
    UiObject.Parent = MainFrame.Buttons
    UiObject.Name = 'PopUp'

    EffectUtil:Tween(UiObject, {.25}, {GroupTransparency = 0})
    EffectUtil:Tween(UiObject.UIStroke, {.25}, {Transparency = 0})
    EffectUtil:Tween(UiObject.UIScale, {.15, 'Quad', 'In'}, {Scale = 1})

    local ClonedAgent = AgentModel:Clone()
    local NewCamera = Instance.new('Camera')
    ClonedAgent:PivotTo(CFrame.new())
    ClonedAgent.Parent = UiObject.Main.WorldModel
    NewCamera.CFrame = ClonedAgent:GetPivot() * CFrame.new(0, 1.5, -160) * CFrame.Angles(0, math.pi, 0)
    NewCamera.FieldOfView = 1
end

function DisplayDodgeCount(MainFrame, Dodges: number, Max: number)
    local SkillList = MainFrame.Buttons
    local DodgeSkill = SkillList:FindFirstChild("Dodge")
    local SkillAssets = Assets.Interface.Combat.Skill

    if DodgeSkill then
        local Charges = DodgeSkill.Charges;
        local Count = #Charges:GetChildren() - 1;
        
        if Count ~= Max then
            for _, Item in Charges:GetChildren() do
                if Item:IsA('Frame') then
                    Item:Destroy()
                end
            end

            for n = 1, Max do
                local NewCharge = SkillAssets.DodgeCharge:Clone()
                NewCharge.Name = tostring(n)
                NewCharge:SetAttribute('On', true)
                NewCharge.Parent = Charges;
            end

            if Dodges == Max then return end
        end

        for _, Item in Charges:GetChildren() do
            if not Item:IsA('Frame') then continue end

            local Scaler = Item.UIScale
            local Id = tonumber(Item.Name, 10)
            local IsOn = Item:GetAttribute('On')
            if IsOn and Dodges < Id then
                Item:SetAttribute('On', false)

                Item.BackgroundColor3 = Color3.new()
            elseif not IsOn and Dodges >= Id then
                Item:SetAttribute('On', true)

                Item.BackgroundColor3 = Color3.new(1, 1, 1)
                Scaler.Scale = 0.8
                EffectUtil:Tween(Scaler, {0.25, 'Back'}, {Scale = 1})


                ---
                local EffectCircle = SkillAssets.EffectCircle:Clone()
                EffectCircle.Parent = Item;
                EffectUtil:Tween(EffectCircle, { .2, 'Sine' }, {Transparency = 1})
                EffectUtil:Tween(EffectCircle.UIScale, { .25, 'Quad' }, {Scale = 2})
                EffectUtil:CleanUp(EffectCircle, .25)
            end
        end
    end
end

-- Publics
-- Link the frame
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Moveset", true)

    return Main
end

function Component:PopUpAgent(Name: string)
    PopUpAgentIcon(Name)
end

function Component:DeletePopUp()
    local MainFrame = Component:GetFrame()
    local AgentPopup = MainFrame.Buttons:FindFirstChild("PopUp")

    if AgentPopup then
        AgentPopup.Name = '__deleting'
        ToggleButton("Swap_Forth", true)

        EffectUtil:Tween(AgentPopup, {.25}, {GroupTransparency = 1})
        for _, UIStroke in AgentPopup:GetChildren() do
            if UIStroke:IsA("UIStroke") then
                EffectUtil:Tween(UIStroke, {.25}, {Transparency = 1})
            end
        end
        EffectUtil:Tween(AgentPopup.UIScale, {.3, 'Quad', 'In'}, {Scale = 0.6})
    end
end

function Component:Init()
    --
    local MainFrame = Component:GetFrame()

    Inputs:OnInputTypeChanged(function(Type: Enum.UserInputType)  
        for _, Button in MainFrame.Buttons:GetChildren() do
            if Button:IsA('Frame') then
                SetupKey(Button)
            end
        end
    end)

    --
    for ButtonName in FramePositions do
        CreateSkillObject(ButtonName)

        Inputs:Bind(ButtonName, {Release = true, Callback = function(State)
            if State == 'Begin' then
                Press(ButtonName)
            else
                Release(ButtonName)
            end
        end})
    end

    Component:GetScope():Observer(InterfaceStates.Characters):onChange(function()
        local Character, id = AgentsLib:GetCurrent(Player:GetAttribute("ReplicationId"))
        if not Character then
            return
        end

        SetUltBarFill(Component:Peek(InterfaceStates.UltBar[id]) / 100)
        RefreshUltimateIcon(Character.Name)
    end)

    for charID, UltBarValue in InterfaceStates.UltBar do
        Component:GetScope():Observer(UltBarValue):onChange(function()
            local _, CurrentId = AgentsLib:GetCurrent(Player:GetAttribute('ReplicationId') :: number)

            if CurrentId == charID then
                SetUltBarFill(Component:Peek(UltBarValue) / 100)
            end
        end)
    end
end

function Component:DisplayDodges(Current: number, Max: number)
    local MainFrame = Component:GetFrame()

    DisplayDodgeCount(MainFrame, Current, Max)
end

function Component:PlayCooldown(Skill: string, Time: number)
    local MainFrame = Component:GetFrame()
    local Buttons = MainFrame:FindFirstChild("Buttons")
    local SkillFrame = Buttons:FindFirstChild(Skill) :: Frame & {Cooldown: CanvasGroup & {Fill: Frame}}

    if not(SkillFrame) or not(SkillFrame:FindFirstChild('Cooldown')) then
        return
    end

    local FillCooldownObj = SkillFrame.Cooldown.Fill

    FillCooldownObj.Size = UDim2.fromScale(1, 1)
    EffectUtil:Tween(FillCooldownObj, {Time, 'Quad'}, {Size = UDim2.fromScale(1, 0)})
end

return Component