local Prompts = {}

function Prompts:CreatePromptOnPart(BasePart: BasePart, Type: number)
    local Attachment = Instance.new("Attachment")
    Attachment.Name = "PromptAttachment"
    Attachment.Parent = BasePart

    local Prompt = Instance.new("ProximityPrompt")
    Prompt.RequiresLineOfSight = false
    Prompt.ActionText = "Open"
    Prompt.ObjectText = "Chest"
    Prompt.MaxActivationDistance = 25
    Prompt.Parent = Attachment

    Prompt:SetAttribute("Type", Type)

    return Prompt
end

return Prompts