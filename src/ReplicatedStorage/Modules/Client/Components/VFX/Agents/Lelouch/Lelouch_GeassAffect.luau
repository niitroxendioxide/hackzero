const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets;

const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
const Enemies = require("@game/ReplicatedStorage/Modules/Shared/Libraries/Enemies")

return function(EnemyId: number, ...)
    const Args = {...}
    const TimeModifier: number = Args[1] or 1;

    const EnemyObj = Enemies:GetEnemy(EnemyId)
    const LelouchVFX = Assets.Effects.Agents.Lelouch;

    const Geass = Effects:Create(LelouchVFX.Geass, 2.35)
    Geass:PivotTo(EnemyObj:GetModel():GetPivot())

    Effects:Emit(Geass, true)
    Effects:Weld(Geass, EnemyObj:GetModel().PrimaryPart)

    const Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.fromRGB(0, 255, 102)
    Highlight.OutlineColor = Color3.fromRGB(218, 34, 255)
    Highlight.OutlineTransparency = .75
    Highlight.FillTransparency = 2.5 + TimeModifier;
    Highlight.Parent = EnemyObj:GetModel()
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded;

    Effects:Tween(Highlight, { 0.7 * TimeModifier, "Quad" }, {FillTransparency = 1})
    Effects:Tween(Highlight, { 1.25 * TimeModifier, "Quad" }, {OutlineTransparency = 0.99})
    Effects:CleanUp(Highlight, 1.5 * TimeModifier)
end
