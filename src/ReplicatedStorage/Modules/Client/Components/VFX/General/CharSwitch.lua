---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)


---
return function(Character: Model, LevelUp: boolean): ()

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillColor = Color3.new(1, 1, 1);
    Highlight.FillTransparency = 0
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Character

    Effects:Tween(Highlight, { 0.25, 'Quad' }, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, 0.25)

    ---
    local ParticleVFX = Effects:Create(Assets.Effects.General.Lobby[LevelUp and 'LevelUpEffect' or 'CharacterLoadEffect'], 2)
    ParticleVFX:PivotTo(Character:GetPivot())
    Effects:Emit(ParticleVFX)
end