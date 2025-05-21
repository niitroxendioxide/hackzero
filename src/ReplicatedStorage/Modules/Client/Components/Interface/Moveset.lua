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

--
local FramePositions: {[string]: UDim2} = {
    Basic_Attack = UDim2.fromScale(0.857, 0.842),
    Dodge = UDim2.fromScale(0.777, 0.842),
    Swap_Forth = UDim2.fromScale(0.938, 0.842),
    Special = UDim2.fromScale(0.938, .625)
}

local FrameScales: {[string]: number} = {
    Basic_Attack = 1,
    Dodge = .85,
    Swap_Forth = .85,
    Special = .85,
}

--
local Component = ComponentClass.new("AFK", "AFK")

-- Privates
-- Convert a key name into its correct shown key
local function FixKeyName(Key: string): string
    if string.match(Key, 'MouseButton') then
        return 'MB'..string.sub(Key, #Key, #Key)
    end

    return Key
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
    local Object = InterfaceFolder.Combat.Skill.SkillFrame:Clone() :: Types.FrameButtonStructure
    local KeySize = 0.3 + (0.04 * #KeyName)

    Object.Name = Name
    Object.UIScale.Scale = FrameScales[Name] or 1
    Object.Icon.Image = IconDatabase.PREFIX .. (IconDatabase.Skills[Name] or 0)
    Object.Key.Size = UDim2.fromScale(KeySize, 0.3)
    Object.Key.KeyBind.Text = KeyName
    Object.Position = FramePositions[Name]
    Object.Parent = MainFrame.Buttons
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
end

function Component:PlayCooldown(Skill: string, Time: number)
    local MainFrame = Component:GetFrame()
    local Buttons = MainFrame:FindFirstChild("Buttons")
    local SkillFrame = Buttons:FindFirstChild(Skill) :: {Cooldown: CanvasGroup & {Fill: Frame}}

    if not SkillFrame then
        return
    end

    local FillCooldownObj = SkillFrame.Cooldown.Fill

    FillCooldownObj.Size = UDim2.fromScale(1, 1)
    EffectUtil:Tween(FillCooldownObj, {Time, 'Quad'}, {Size = UDim2.fromScale(1, 0)})
end

return Component