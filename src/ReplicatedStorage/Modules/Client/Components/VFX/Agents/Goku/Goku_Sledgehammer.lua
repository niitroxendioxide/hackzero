


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)

---
return function(
    Caster: Types.Caster,
    State: boolean
): ()
    --
    if State == false then
        local SledgeHammerVFX = Effects:Create(Assets.Goku.SledgehammerCharge, 10)
        SledgeHammerVFX:PivotTo(Caster:GetPivot())
        Effects:Weld(SledgeHammerVFX, Caster:GetModel().PrimaryPart)

        Effects:Emit(SledgeHammerVFX)

        local act_time = 0;
        while act_time <= 0.18 do
            act_time += Effects:Wait()

            local Cast = Effects:CastMapRaycast(Caster:GetPivot(), vector.create(0, -1000))
            if not Cast then
                Effects:Toggle(SledgeHammerVFX.Ground, false)
            else
                Effects:Toggle(SledgeHammerVFX.Ground, true)
            end
        end

        Effects:Toggle(SledgeHammerVFX, false)
    else
        EffectsLib:Play("Goku_M1_1", Caster, CFrame.new(0, 3.25, -2.75) * CFrame.Angles(math.rad(-72), 0, 0))
        EffectsLib:Play("Goku_M1_4", Caster, 6)
    end
end