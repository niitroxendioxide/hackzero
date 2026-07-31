---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)


local Offset = CFrame.new(0, 0, -2)

---
return function(Target: Types.ClientEnemy, HitCount: number, HitFreq: number): ()
    local NarutoVfx = Assets.Effects.Agents.Naruto
    local TargetModel = Target:GetModel()

    local TotalTimeWaited = HitCount * HitFreq
    local BigRasengan = Effects:Create(NarutoVfx.HitRasengan, TotalTimeWaited)
    BigRasengan:ScaleTo(0.175)
    BigRasengan:PivotTo(TargetModel.PrimaryPart.CFrame * Offset)

    local MaxTime = HitFreq * HitCount--math.min(HitFreq * HitCount, 0.75)
    Effects:Weld(BigRasengan.PrimaryPart, TargetModel.PrimaryPart)
    Effects:TweenModel(BigRasengan, 1.3, MaxTime, 'Sine', 'In')
    

    task.wait(TotalTimeWaited)
    local Explosion = Effects:Create(NarutoVfx.RasenganExplode, 3)
    Explosion:PivotTo(TargetModel.Torso.CFrame * Offset)
    Effects:Emit(Explosion, true)
end