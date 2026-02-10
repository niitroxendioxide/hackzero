


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster
): ()
    --
    local KunaiVFX = Assets.Sasuke.Kunai
    local Model = Caster:GetModel()

    local ThreadVFX = Effects:Create(KunaiVFX.Thread, 2)
    ThreadVFX:PivotTo(Model['Left Arm'].CFrame * CFrame.new(0, -0.85, 0))
    Effects:Weld(ThreadVFX, Model['Left Arm'])

    for i = -1, 1, 0.5 do
        local Offset = CFrame.new(math.sin(math.rad(i * 35)) * 15, 0, math.cos(math.rad(i * 33)) * -7)
        local Ground = Effects:CastMapRaycast(Caster:GetPivot() * Offset, vector.create(0, -2500))
        if Ground then
            local BaseCF = CFrame.lookAt(Model:GetPivot().Position, Ground.Position)
            local Kunai = Effects:Create(KunaiVFX.Kunai, 3)
            Kunai:PivotTo(BaseCF)

            if (i == 0) then
                local EndAttachment = ThreadVFX.End
                local curworldcf = EndAttachment.WorldCFrame
                EndAttachment.Parent = Kunai
                EndAttachment.WorldCFrame = curworldcf

                Effects:Tween(EndAttachment, { .4, 'Sine' }, {Position = vector.create(0, 0, 1.125)})

                ThreadVFX.Grab.Beam.CurveSize0 = Effects:Random(-8, 8)
                ThreadVFX.Grab.Beam.CurveSize1 = Effects:Random(-8, 8)

                Effects:Tween(ThreadVFX.Grab.Beam, { .6, 'Elastic' }, {CurveSize0 = 0, CurveSize1 = 0})

                task.delay(1, function()
                    Effects:Tween(ThreadVFX.Grab.Beam, { 0.25, 'Sine' }, {Width0 = 0, Width1 = 0})
                    Effects:CleanUp(ThreadVFX, 0.25)
                end)
            end

            Effects:Tween(Kunai, { .1 }, { CFrame = CFrame.lookAlong(Ground.Position, BaseCF.LookVector) * CFrame.new(0, 0, 0.33) })
            task.delay(1, function()
                Effects:Tween(Kunai, { 0.35 }, {Transparency = 1})
            end)

            ---
            local HitEffect = Effects:Create(KunaiVFX.Effect, 3)
            HitEffect:PivotTo(CFrame.lookAlong(Ground.Position, Ground.Normal))
            Effects:Emit(HitEffect)
        end

    end
end