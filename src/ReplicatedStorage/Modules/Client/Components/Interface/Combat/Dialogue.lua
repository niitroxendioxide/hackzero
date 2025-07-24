local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local BaseClass = require(Client.Classes.Interface)

local Component = BaseClass.new("Dialogue", "Cutscenes")
local Threads = {}

function Component:Link(Player: Player)
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Dialogues", true)

    return Main
end

function Component:Init()

end

function Component:ShowDialogue(Data: {Speaker: string, Text: string, NextDialogue: number})
    self:Set(true)

    local CurrentFrame = self:GetFrame()
    local DialogueBox = CurrentFrame.Area :: {Speaker: TextLabel, Label: TextLabel}

    for _, Thread in Threads do
        task.cancel(Thread)
    end

    Threads = {}

    if DialogueBox.Speaker.Text ~= Data.Speaker then
        DialogueBox.Speaker.UIScale.Scale = 0
        DialogueBox.Label.UIScale.Scale = 0

        Effects:Tween(DialogueBox.Label.UIScale, {.325, 'Back'}, {Scale = 1})
        Effects:Tween(DialogueBox.Speaker.UIScale, {.25, 'Back'}, {Scale = 1})
    end

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

    local NextTime = Data.NextDialogue or 7

    table.insert(Threads, task.delay(NextTime + 0.25, function()
        Effects:Tween(DialogueBox.Speaker, {0.45, 'Quad'}, {TextTransparency = 1})
        Effects:Tween(DialogueBox.Label, {0.45, 'Quad'}, {TextTransparency = 1})
        Effects:Tween(DialogueBox.Speaker.UIStroke, {.3, 'Quad'}, {Transparency = 1})
        Effects:Tween(DialogueBox.Label.UIStroke, {.3, 'Quad'}, {Transparency = 1})
    end))
end

return Component
