local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Assets = ReplicatedStorage.Assets

local CutsceneEffects = require(ReplicatedStorage.Modules.Client.Libraries.CutsceneEffects)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local BaseClass = require(Client.Classes.Interface)

local Component = BaseClass.new("Dialogue", "Cutscenes")
local Threads = {}
local Tweens = {} :: {Tween}
local Connections = {}
local ShowHUDFunction = nil

type Main = Frame & {Options: Frame & {UIListLayout: UIListLayout}}
type Dialoguebox = {Speaker: TextLabel, Label: TextLabel}
export type Data = {Speaker: string, Text: string, NextDialogue: number, Options: {string}, Enables: {Trigger: {Id: string, Name: string}}}

function Component:Link(Player: Player)
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Dialogues", true)

    return Main
end

function Component:Init()
    Component.Completed = Signal.new()
    Component.ButtonPressed = Signal.new() :: Signal.ScriptSignal<string>
    Component.EventTriggered = Signal.new() :: Signal.ScriptSignal<number, string>
end

function Component:ShowDialogue(Data: Data, HideHUD)
    self:Set(true)

    local CurrentFrame = self:GetFrame()
    local DialogueBox = CurrentFrame.Area :: Dialoguebox
    local NextTime = Data.NextDialogue or 7

    if not ShowHUDFunction and HideHUD then
        ShowHUDFunction = CutsceneEffects:HideHUD(NextTime * 2)
    end

    for _, Thread in Threads do
        task.cancel(Thread)
    end

    for _, Tween: Tween in Tweens do
        Tween:Cancel()
    end

    Threads = {}

    if DialogueBox.Speaker.Text ~= Data.Speaker then
        DialogueBox.Speaker.UIScale.Scale = 0
        DialogueBox.Label.UIScale.Scale = 0

        Effects:Tween(DialogueBox.Label.UIScale, {.325, 'Back'}, {Scale = 1})
        Effects:Tween(DialogueBox.Speaker.UIScale, {.25, 'Back'}, {Scale = 1})
    end

    table.insert(Tweens, Effects:Tween(CurrentFrame.DotsWhite, {.15, 'Quad'}, {ImageTransparency = 0.5}))
    table.insert(Tweens, Effects:Tween(CurrentFrame.DotsDark, {.175, 'Quad'}, {ImageTransparency = 0.5}))
    table.insert(Tweens, Effects:Tween(CurrentFrame.Bg, {.175, 'Quad'}, {ImageTransparency = 0.45}))
    table.insert(Tweens, Effects:Tween(CurrentFrame.Line, {.175, 'Quad'}, {Size = UDim2.new(0.35, 0, 0, 2)}))

    DialogueBox.Visible = true
    DialogueBox.Speaker.TextTransparency = 0
    DialogueBox.Speaker.UIStroke.Transparency = 0

    DialogueBox.Label.TextTransparency = 0
    DialogueBox.Label.UIStroke.Transparency = 0

    DialogueBox.Speaker.Text = Data.Speaker

    table.insert(Threads, task.spawn(function()
        for i = 1, #Data.Text do
            DialogueBox.Label.Text = string.sub(Data.Text, 1, i)

            task.wait(1/60)
        end
    end))

    local function Destroy()
        table.insert(Tweens, Effects:Tween(CurrentFrame.DotsWhite, {.15, 'Quad'}, {ImageTransparency = 1}))
        table.insert(Tweens, Effects:Tween(CurrentFrame.DotsDark, {.175, 'Quad'}, {ImageTransparency = 1}))
        table.insert(Tweens, Effects:Tween(CurrentFrame.Bg, {.3, 'Quad'}, {ImageTransparency = 1}))
        table.insert(Tweens, Effects:Tween(CurrentFrame.Line, {.175, 'Quad'}, {Size = UDim2.new(0, 0, 0, 2)}))

        table.insert(Tweens, Effects:Tween(DialogueBox.Speaker, {0.45, 'Quad'}, {TextTransparency = 1}))
        table.insert(Tweens, Effects:Tween(DialogueBox.Label, {0.45, 'Quad'}, {TextTransparency = 1}))
        table.insert(Tweens, Effects:Tween(DialogueBox.Speaker.UIStroke, {.3, 'Quad'}, {Transparency = 1}))
        table.insert(Tweens, Effects:Tween(DialogueBox.Label.UIStroke, {.3, 'Quad'}, {Transparency = 1}))

        if ShowHUDFunction then
            task.spawn(ShowHUDFunction)
            ShowHUDFunction = nil
        end

        Component.Completed:Fire()
    end

    if Data.Options then
        for Id, Option in Data.Options do
            Component:CreateOptionButton(Option, Id)
        end

        Component.ButtonPressed:Wait()
        table.insert(Threads, task.delay(0.25, Destroy))
    else
        --[[table.insert(Connections, UserInputService.InputBegan:Connect(function(Input: InputObject, Gp)
            if Gp then return  end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                table.insert(Threads, task.delay(0.25, Destroy))
            end
         end))]]

        table.insert(Threads, task.delay(NextTime + 0.25, Destroy))
    end
end

function Component:ClearOptions()
    local CurrentFrame = self:GetFrame() :: Main

    for _, Connection in Connections do
        Connection:Disconnect()
    end

    for _, Option in CurrentFrame.Options:GetChildren() do
        if Option:IsA("TextButton") then
            Option:Destroy()
        end
    end
end

function Component:CreateOptionButton(Text: string, Id: number)
    local CurrentFrame = self:GetFrame() :: Main

    local Option = Assets.Interface.Dialogue.Option:Clone()
    Option.Label.Text = Text
    Option.Number.Label.Text = Id
    Option.Parent = CurrentFrame.Options

    table.insert(Connections, Option.MouseButton1Click:Once(function()
        Component.ButtonPressed:Fire(Text)

        Component:ClearOptions()
    end))

    table.insert(Connections, Option.MouseEnter:Connect(function()
        Effects:Tween(Option.Bg, {.25, 'Quad'}, {BackgroundTransparency = 0.75})
        Effects:Tween(Option.Bg.UIStroke, {.17, 'Sine'}, {Transparency = 0.25})
    end))

    table.insert(Connections, Option.MouseLeave:Connect(function()
        Effects:Tween(Option.Bg, {.25, 'Quad'}, {BackgroundTransparency = 0.9})
        Effects:Tween(Option.Bg.UIStroke, {.17, 'Sine'}, {Transparency = 0.5})
    end))
end

function Component:PlaySequence(Sequence: {{}}, HideHUD: boolean, NPCName: string?)
    task.spawn(function()
        for Id, DialogueObject in Sequence do
            if DialogueObject.Enables then
                Component.EventTriggered:Fire(Id, NPCName)
            end

            Component:ShowDialogue(DialogueObject, HideHUD)

            if not DialogueObject.Options then
                local Time = DialogueObject.NextDialogue or 4
                task.wait(Time)
            end
        end
    end)
end

return Component
