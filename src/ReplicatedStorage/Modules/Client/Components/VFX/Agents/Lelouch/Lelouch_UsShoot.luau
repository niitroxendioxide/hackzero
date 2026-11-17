const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Assets = ReplicatedStorage.Assets

const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
const Offset = CFrame.new(0.288, 0.959, -6.592);


return function(Caster: any, ...)
    const LelouchVFX = Assets.Effects.Agents.Lelouch;

    const Model = Caster:GetModel();
    const Gun = Model:FindFirstChild("Gun")

    const Shoot = Effects:Create(LelouchVFX.ShootVFX, 4)
    Shoot:PivotTo(Model:GetPivot() * Offset)
    Effects:Weld(Shoot.PrimaryPart, Model.PrimaryPart)
    Effects:Emit(Shoot, true)
    Effects:Emit(Gun)
end
