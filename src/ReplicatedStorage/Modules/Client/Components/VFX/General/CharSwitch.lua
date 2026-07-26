---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)


---
return function(Character: Model, LevelUp: boolean, IsCompanion: boolean): ()

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillColor = Color3.new(1, 1, 1);
    Highlight.FillTransparency = 0
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Character

    Effects:Tween(Highlight, { 0.25, 'Quad' }, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, 0.25)

    ---
    local EffectName = LevelUp and 'LevelUpEffect' or (IsCompanion and 'CompanionLoadEffect' or 'CharacterLoadEffect')
    local Offset = IsCompanion and CFrame.new(0, -0.75, 0) or CFrame.new(0, 0, 0)
    local ParticleVFX = Effects:Create(Assets.Effects.General.Lobby[EffectName], 2)
    ParticleVFX:PivotTo(Character:GetPivot() * Offset)
    Effects:Emit(ParticleVFX)
end