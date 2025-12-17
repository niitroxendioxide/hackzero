


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(ReplicatedStorage.Modules.Client.Libraries.Effects)

---
return function(
    Caster: Types.Caster,
    Id: number?
): ()
    --
    local VfxRig = Effects:Create(Assets.Goku.BasicAttack.TrailVfxRig, 3)
    VfxRig:PivotTo(Caster:GetModel():GetPivot())

    if Id == 3 then
        --VfxRig:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0, -2.5))
        VfxRig.PrimaryPart.Anchored = false
        Effects:Weld(VfxRig.PrimaryPart, Caster:GetModel().PrimaryPart)

        EffectsLib:Play('Goku_M1_1', Caster, CFrame.new(0.071, 3.801, -2.707) * CFrame.Angles(math.rad(72), 0, 0))
    end

    Animation:Play(VfxRig, Animation:GetAnim('Characters.Goku.Abilities.Vfx.Trail_'..(Id or 2)))
    if Id == 2 then
        Effects:Emit(VfxRig.HumanoidRootPart.vfx)
    end

    task.delay(0.25, function()
        for _, Trail in VfxRig.CameraReference:GetDescendants() do
            if Trail:IsA("Trail") then
                Trail.Enabled = false
            end
        end
    end)
end