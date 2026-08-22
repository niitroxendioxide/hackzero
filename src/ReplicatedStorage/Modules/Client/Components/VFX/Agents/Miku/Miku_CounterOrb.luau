---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
return function(
    Caster: Types.Caster,
    Origin: CFrame,
    Goal: CFrame,
    TravelTime: number
): ()

    
    local MikuAssets = Assets.Miku
    local Model = Caster:GetModel()

    local Init = Model:GetPivot() * Origin;
    local End = Model:GetPivot() * Goal;
    local Look = CFrame.lookAt(Init.Position, End.Position).LookVector
    local BlastModel = Effects:Create(MikuAssets.MikuBlast, TravelTime)

    local CastEffect = Effects:Create(MikuAssets.CastBallEffect, 3)
    CastEffect:PivotTo(CFrame.lookAlong(Init.Position, Look))

    Effects:Emit(CastEffect, true)

    task.spawn(function()
        local Start = os.clock()
        while true do
            local Alph = (os.clock() - Start) / TravelTime
            if Alph >= 1 then
                break
            end

            local NewPos = CFrame.lookAlong((Init:Lerp(End, Alph)).Position, Look)
            BlastModel:PivotTo(NewPos)

            task.wait()
        end

        local ModelScale = 1.25

        local Explosion = Effects:Create(MikuAssets.M1Explosion, 3)
        Explosion:PivotTo(End)
        Explosion:ScaleTo(ModelScale)

        Effects:Emit(Explosion, true)
    end)
end