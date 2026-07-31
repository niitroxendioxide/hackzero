


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLibrary = require(Client.Libraries.Effects)

---
return function(
    Caster: Types.Caster,
    Time: number,
    NoSlash: boolean
): ()
    --
    Time = Time or 0.45
    --EffectsLibrary:Play("Goku_M1_1", Caster, CFrame.new(0, 3.5, -3.25) * CFrame.Angles(-math.pi * 0.42, 0, math.rad(11)), true)
    if not NoSlash then
        EffectsLibrary:Play("Goku_M1_4", Caster, 5)
    end

    local DashEffect = Effects:Create(Assets.Goku.BasicAttack.DashBack, 2)
    DashEffect.Anchored = false
    DashEffect:PivotTo(Caster:GetModel():GetPivot())
    Effects:Weld(DashEffect, Caster:GetModel().PrimaryPart)
    Effects:RecolorToGroundColor(Caster:GetModel():GetPivot().Position, DashEffect.att:GetChildren())

    task.delay(Time, function()
        Effects:Toggle(DashEffect, false)
    end)
end
