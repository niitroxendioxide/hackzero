


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
    local SasukeVFX = Assets.Sasuke
    local Offset = CFrame.new(0, 0.65, 0)

    local Model = Caster:GetModel()
    local LogModel: MeshPart = Effects:Create(SasukeVFX.Log, 3)
    LogModel:PivotTo(Model:GetPivot() * Offset * CFrame.Angles(0, Effects:Random(-math.pi, math.pi) * 0.5, Effects:Random(-math.pi, math.pi) * 0.25))
    LogModel.AssemblyLinearVelocity = vector.create(0, 16, 0)

    Effects:Emit(LogModel)

    Effects:CleanUp(function()
        Effects:Tween(LogModel, { 0.45, 'Sine' }, { Size = vector.zero })
    end, 2)
end