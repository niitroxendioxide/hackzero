const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets;

const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
const Enemies = require("@game/ReplicatedStorage/Modules/Shared/Libraries/Enemies")

return function(EnemyId: number, ...)
    const EnemyObj = Enemies:GetEnemy(EnemyId)
    const LelouchVFX = Assets.Effects.Agents.Lelouch;

    const Geass = Effects:Create(LelouchVFX.Geass, 2.25)
    Geass:PivotTo(EnemyObj:GetModel():GetPivot())

    Effects:Emit(Geass, true)
    Effects:Weld(Geass, EnemyObj:GetModel().PrimaryPart)

    const Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.fromRGB(33, 255, 151)
    Highlight.OutlineColor = Color3.fromRGB(218, 34, 255)
    Highlight.OutlineTransparency = 0
    Highlight.FillTransparency = 1.5
    Highlight.Parent = EnemyObj
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded;

    Effects:Tween(Highlight, { 0.45, "Quad" }, {FillTransparency = 1})
    Effects:Tween(Highlight, { 0.7, "Quad" }, {OutlineTransparency = 0.99})
    Effects:CleanUp(Highlight, 1)
end
