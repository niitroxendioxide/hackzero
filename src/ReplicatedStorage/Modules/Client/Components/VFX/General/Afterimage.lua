local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Abilities = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

local AfterImageInfo = { 0.5, 'Quad' }

return function(
    Caster: Abilities.Caster,
    Offset: CFrame?
)

    --[[]]
    Offset = Offset or CFrame.new()
    local ClonedModel = Effects:Create(Caster:GetModel(), 2)

    for _, BasePart in ClonedModel:GetDescendants() do
        if BasePart:IsA("WeldConstraint") or BasePart:IsA("Motor6D") or BasePart:IsA("Weld") or BasePart:IsA('Highlight') then
            BasePart:Destroy()
            continue
        end

        if (BasePart:IsA("BasePart")) or (BasePart:IsA("Decal")) or (BasePart:IsA("Texture")) then
            if BasePart:IsA('BasePart') then
                BasePart.Anchored = true
            end

            Effects:Tween(BasePart, AfterImageInfo, { Transparency = 1 })
        end
    end

    ClonedModel:PivotTo(ClonedModel:GetPivot() * Offset)
end
