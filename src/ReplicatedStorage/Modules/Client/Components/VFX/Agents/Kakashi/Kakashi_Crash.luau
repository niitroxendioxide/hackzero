local ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")

return function(At: CFrame)
    const KakashiVfx = Assets.Effects.Agents.Kakashi

    local Ground = Effects:CastMapRaycast(At.Position, vector.create(0, -250))
    if Ground then
        Effects:CreateRocks(Ground, vector.create(1.95, 0.75, 1.95), {9, 12}, {6, 9}, {-13, 13})
    end

    const ExplosionVFX = Effects:Create(KakashiVfx.ElectricExplosion, 4)
    ExplosionVFX:PivotTo(At)
    Effects:Emit(ExplosionVFX, true)
end
