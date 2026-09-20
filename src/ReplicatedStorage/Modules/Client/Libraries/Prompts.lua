local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Prompts = {
    __Disabled = false,
}

local All = {}
local States = {}

function Prompts:SetState(Prompt: ProximityPrompt, State: boolean)
    States[Prompt] = State
end

function Prompts:CreatePromptOnPart(BasePart: BasePart, Type: number | any, ActionText: string, ObjectText: string, Distance: number?, Tags: { string }?)
    local Attachment = Instance.new("Attachment")
    Attachment.Name = "PromptAttachment"
    Attachment.Parent = BasePart

    local Prompt = Instance.new("ProximityPrompt")
    Prompt.RequiresLineOfSight = false
    Prompt.ActionText = ActionText or "Interact"
    Prompt.ObjectText = ObjectText or GameEnum.KeyLookup(GameEnum.InteractionType, Type)
    Prompt.MaxActivationDistance = Distance or 15
    Prompt.KeyboardKeyCode = Enum.KeyCode.F
    Prompt.ClickablePrompt = false
    Prompt.Enabled = not Prompts.__Disabled

    --if Type == GameEnum.InteractionType.UIInteraction or Type == GameEnum.InteractionType.LobbyNPC then
        Prompt.Style = Enum.ProximityPromptStyle.Custom
        Prompt.HoldDuration = 0.01
    --end

    if typeof(Tags) == 'table' and typeof(Tags[1]) == 'string' then
        for _, Tag in Tags do
            Prompt:AddTag(Tag)
        end
    end
    
    Prompt.Parent = Attachment

    States[Prompt] = true
    table.insert(All, Prompt)

    Prompt:SetAttribute("Type", Type)

    return Prompt
end

function Prompts:DisableAll()
    Prompts.__Disabled = true

    for _, Prompt in All do
        Prompt.Enabled = false
    end
end

function Prompts:EnableAll()
    Prompts.__Disabled = false

    for _, Prompt in All do
        Prompt.Enabled = States[Prompt]
    end
end

return Prompts