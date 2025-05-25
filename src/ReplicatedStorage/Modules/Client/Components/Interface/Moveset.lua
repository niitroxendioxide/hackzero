--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

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

-- Create the skill object on screen
local function CreateSkillObject(Name: string)
    if not FramePositions[Name] then
        return
    end

    local MainFrame = Component:GetFrame()
    local KeyBinding = Inputs:GetEnumFromKey(Name)
    if not KeyBinding then return end

    local KeyEnum = (typeof(KeyBinding) == 'table' and KeyBinding[#KeyBinding] or KeyBinding) :: EnumItem
    local KeyName = FixKeyName(KeyEnum.Name)

    local InterfaceFolder = Assets:FindFirstChild('Interface') :: Types.GenericFolderContainer<Types.FrameButtonStructure>
    local ObjName = InterfaceFolder.Combat.Skill:FindFirstChild(Name == 'Ultimate' and 'UltFrame' or 'SkillFrame')
    if not ObjName then return end

    local Object = ObjName:Clone() :: Types.FrameButtonStructure
    local KeySize = 0.3 + (0.04 * #KeyName)

    local Icon = (IconDatabase.Skills[Name] or 0)
    Object.Name = Name
    Object.UIScale.Scale = FrameScales[Name] or 1
    Object.Icon.Image = IconDatabase.PREFIX .. Icon
    Object.Key.Size = UDim2.fromScale(KeySize, 0.3)
    Object.Key.KeyBind.Text = KeyName
    Object.Position = FramePositions[Name]
    Object.Parent = MainFrame.Buttons

    if Name == 'Ultimate' then
        local CurrentAgentName = AgentsLib:GetCurrentName(Player:GetAttribute('ReplicationId') :: number)

        RefreshUltimateIcon(CurrentAgentName)
    end
end

local function Press(ButtonName: string)
    if not FrameScales[ButtonName] then return end
    local MainFrame = Component:GetFrame()
    local ButtonObj = MainFrame.Buttons:FindFirstChild(ButtonName)

    EffectUtil:Tween(ButtonObj.UIScale, {.25, 'Cubic'}, {Scale = FrameScales[ButtonName] * 0.8})
end

local function Release(ButtonName: string)
    if not FrameScales[ButtonName] then return end

    local MainFrame = Component:GetFrame()
    local ButtonObj = MainFrame.Buttons:FindFirstChild(ButtonName)

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

    EffectUtil:Tween(FillStroke.UIGradient, {.2, 'Sine'}, {Offset = Offset})
    EffectUtil:Tween(UltBar.Meter.Fill, {.2, 'Sine'}, {Size = UDim2.fromScale(1, Coefficient)})
    EffectUtil:Tween(UltBar.Meter.Fill, {.2}, {BackgroundColor3 = Color})
    FillStroke.UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.499, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color),
        ColorSequenceKeypoint.new(1,Color),
    }

    if Thread then
        task.cancel(Thread)
    end

    if LastCoefficient ~= Coefficient and Coefficient == 1 then
        local H = Color:ToHSV()
        local Rotated = H - 25
        if Rotated < 0 then Rotated += 360 end

        UltBar.UIStroke.Color = Color
        UltBar.UIStroke.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromHSV(Rotated/360, 50/255, 200/255)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }

        UltBar.UIScale.Scale = .8
        EffectUtil:Tween(UltBar.UIScale, {.25, 'Back'}, {Scale = FrameScales.Ultimate})
        UltBar.UICorner.CornerRadius = UDim.new(.5, 0)
        EffectUtil:Tween(UltBar.UICorner, {.3, 'Back'}, {CornerRadius = UDim.new(.3)})

        Thread = task.spawn(function()
            local Angle = 0
            local Rotation = 0
            local Grad = UltBar.UIStroke.UIGradient
            while true do
                local Delta = task.wait()

                UltBar.UIStroke.Thickness = 3.5 - math.cos(math.rad(Angle)) * 1.5
                Angle += Delta * 280
                Rotation += Delta * 133
                Grad.Rotation = Rotation
            end
        end)
    elseif Coefficient < 1 then
        EffectUtil:Tween(UltBar.UIStroke, {.3}, {Thickness = 3, Color = Color3.new()})
    end

    LastCoefficient = Coefficient
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

function Component:Init()
    --
    --local MainFrame = Component:GetFrame()

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