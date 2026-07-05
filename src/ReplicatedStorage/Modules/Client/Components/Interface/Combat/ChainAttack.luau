local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Client = ReplicatedStorage.Modules.Client
local Assets = ReplicatedStorage.Assets
local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local Interface = require(Client.Classes.Interface)

local Component = Interface.new("ChainAttack", "HUD")

local Threads = {}
local SwitchIcons = {
    [GameEnum.Device.Desktop] = {
        Left = 7031930012,
        Right = 7049040343,
    },

    [GameEnum.Device.Console] = {
        Right = 82590775321190,
        Left = 93081003637759,
    }
}


function Component:Link()
    local PlayerGui = Players.LocalPlayer.PlayerGui
    local HUD = PlayerGui:WaitForChild("FullScreenHUD", 10);
    if not HUD then return end;

    return HUD.Screen:WaitForChild("ChainAttack")
end

---
function UpdateKeyIcons()
    local GUI = Component:GetFrame()

    local Left = GUI.LeftOption.Key.Icon
    local Right = GUI.RightOption.Key.Icon
    local DeviceIcons = SwitchIcons[Inputs:GetDevice()] or SwitchIcons[GameEnum.Device.Desktop]

    Left.Image = 'rbxassetid:// ' .. DeviceIcons.Left
    Right.Image = 'rbxassetid:// ' .. DeviceIcons.Right
end

function CreateAgentModel(Viewport: ViewportFrame, Agent: string)
    local AgentModel = Assets.Characters.Agents:FindFirstChild(Agent, true)
    if not AgentModel then
        AgentModel = Assets.Characters.Template
    end

    Viewport.WorldModel:ClearAllChildren();

    local Cloned = AgentModel:Clone();
    Cloned:PivotTo(CFrame.new())
    Cloned.Parent = Viewport.WorldModel;

    local NewCamera = Instance.new('Camera')
    NewCamera.FieldOfView = 1
    NewCamera.CFrame = CFrame.new(0, 1.75, -180) * CFrame.Angles(0, math.pi, 0)
    NewCamera.Parent = Viewport.WorldModel
    Viewport.CurrentCamera = NewCamera
end

---
local CompThread: thread? = nil;
function Component:Show( AgentNames: { string } )
    if CompThread then
        task.cancel(CompThread)
        CompThread = nil
    end

    for _, Thread in Threads do
        task.cancel(Thread)
    end

    Threads = {}

    local MainFrame = Component:GetFrame()

    MainFrame.Visible = true
    
    MainFrame.LeftOption.UIScale.Scale = 0
    MainFrame.RightOption.UIScale.Scale = 0
    MainFrame.LeftOption.OuterStroke.Color = Color3.new()
    MainFrame.RightOption.OuterStroke.Color = Color3.new()
    MainFrame.Line.GroupTransparency = 1
    MainFrame.CAText.TextTransparency = 1
    MainFrame.ChoiceText.TextTransparency = 1
    MainFrame.ChoiceText.UIStroke.Transparency = 1
    MainFrame.Line.UIStroke.Transparency = 1
    MainFrame.Borders.ImageTransparency = 1

    Effects:Tween(MainFrame.Borders, { 0.35, 'Quad' }, { ImageTransparency = 0 })
    Effects:Tween(MainFrame.ChoiceText.UIStroke, {.3, 'Quad'}, { Transparency = 0.75 })
    Effects:Tween(MainFrame.ChoiceText, {.3, 'Quad'}, { TextTransparency = 0.85 })
    Effects:Tween(MainFrame.CAText, {.3, 'Quad'}, { TextTransparency = 0 })
    Effects:Tween(MainFrame.LeftOption.UIScale, {.25, 'Back'}, { Scale = 1 })
    Effects:Tween(MainFrame.RightOption.UIScale, {.25, 'Back'}, { Scale = 1 })
    Effects:Tween(MainFrame.Line, {.15, 'Quad'}, { GroupTransparency = 0 })
    Effects:Tween(MainFrame.Line.UIStroke, {.15, 'Quad'}, { Transparency = 0 })

    CreateAgentModel(MainFrame.LeftOption.Viewport, AgentNames[1])
    CreateAgentModel(MainFrame.RightOption.Viewport, AgentNames[2])

    ---
    UpdateKeyIcons()

    MainFrame.Line.Fill.Size = UDim2.fromScale(1, 1)

    Effects:Tween(MainFrame.Line.Fill, {Statics.Chain_Attack_Invulnerability_Time}, { Size = UDim2.fromScale(0, 1) })

    --
    CompThread = task.delay(Statics.Chain_Attack_Invulnerability_Time, function()
        Component:Close()
    end)
end

function Component:Choose(Side: number)
    local MainFrame = Component:GetFrame()
    local FrameToEdit = MainFrame.RightOption

    if Side == 1 then
        FrameToEdit = MainFrame.LeftOption
    end

    FrameToEdit.UIScale.Scale = 0.75
    Effects:Tween(FrameToEdit.UIScale, {.25, 'Back'}, { Scale = 1 })
    Effects:Tween(FrameToEdit.OuterStroke, {.4, 'Quart'}, { Color = Color3.new(1, 1, 1) })

    Component:Close(Side)
end

function Component:Close(Chosen: number?)
    local MainFrame = Component:GetFrame()

    Effects:Tween(MainFrame.ChoiceText.UIStroke, {.3, 'Quad'}, { Transparency = 1 })
    Effects:Tween(MainFrame.ChoiceText, {.3, 'Quad'}, { TextTransparency = 1 })
    Effects:Tween(MainFrame.CAText, {.3, 'Quad'}, { TextTransparency = 1 })
    Effects:Tween(MainFrame.CAText.UIStroke, {.3, 'Quad'}, { Transparency = 1 })
    Effects:Tween(MainFrame.Cancel, {.3, 'Quad'}, { TextTransparency = 1 })
    Effects:Tween(MainFrame.Cancel.UIStroke, {.3, 'Quad'}, { Transparency = 1 })

    if not Chosen then
        Effects:Tween(MainFrame.LeftOption.UIScale, {.15, 'Back'}, { Scale = 0 })
        Effects:Tween(MainFrame.RightOption.UIScale, {.15, 'Back'}, { Scale = 0 })
    elseif Chosen == 1 then
        Effects:Tween(MainFrame.RightOption.UIScale, {.15, 'Back'}, { Scale = 0 })
        table.insert(Threads, task.delay(0.35, function()
            Effects:Tween(MainFrame.LeftOption.UIScale, {.15, 'Back'}, { Scale = 0 })
        end))
    elseif Chosen == 2 then
        Effects:Tween(MainFrame.LeftOption.UIScale, {.15, 'Back'}, { Scale = 0 })
        
        table.insert(Threads, task.delay(0.35, function()
            Effects:Tween(MainFrame.RightOption.UIScale, {.15, 'Back'}, { Scale = 0 })
        end))
    end
    Effects:Tween(MainFrame.Line, {.15, 'Quad'}, { GroupTransparency = 1 })
    Effects:Tween(MainFrame.Line.UIStroke, {.15, 'Quad'}, { Transparency = 1 })
    Effects:Tween(MainFrame.Borders, { 0.35, 'Quad' }, { ImageTransparency = 1 })
end

function Component:Init()
    
end

return Component