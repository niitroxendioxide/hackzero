


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster,
    LeftSide: boolean
): ()
    --
    local Offset = CFrame.new(0.85 * (LeftSide and -1 or 1), 0.76, -2.844)

    local ShootKiBlastVFX = Effects:Create(Assets.Goku.ShootKiBlast, 1)
    ShootKiBlastVFX:PivotTo(Caster:GetModel():GetPivot() * Offset)
    Effects:Emit(ShootKiBlastVFX)

    local KiBlastVFX = Effects:Create(Assets.Goku.KiBlast, 2)
    KiBlastVFX:PivotTo(Caster:GetModel():GetPivot() * Offset)

    KiBlastVFX:ScaleTo(0.001)
    Effects:TweenModel(KiBlastVFX, 1, 0.2)

    local Cleaned = false;
    local function CleanUp()
        if Cleaned then
            return;
        end

        Cleaned = true;

        Effects:Toggle(KiBlastVFX, false)
        Effects:Tween(KiBlastVFX.Ball, {.25}, {Size = vector.zero})

        for _, Beam in KiBlastVFX:GetDescendants() do
            if Beam:IsA('Beam') then
                Effects:Tween(Beam, {0.15}, {Width0 = 0, Width1 = 0})
            end
        end
    end

    Effects:MoveProjectile(KiBlastVFX, vector.create(5, 5, 3), 120, 1, function(): boolean  
        CleanUp()

        local HitKiBlastVFX = Effects:Create(Assets.Goku.KiBlastHit, 1)
        HitKiBlastVFX:PivotTo(KiBlastVFX:GetPivot())
        Effects:Emit(HitKiBlastVFX)

        return true
    end)

    task.delay(1, CleanUp)

end