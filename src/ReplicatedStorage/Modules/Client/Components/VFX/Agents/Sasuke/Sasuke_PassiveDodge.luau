


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local _Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local _Effects = require(Shared.Utility.Effects)
local EffectLibrary = require(Client.Libraries.Effects)

---
return function(
    Caster: Types.AgentClass
): ()
    --
    --local SasukeVFX = Assets.Sasuke

    local Animator = Caster:GetAnimator()
    local Track = Animator:Play('autoDodge' .. math.random(1, 2), {})
    Animator:AddTrackToState('Attacking', Track, 0.05)
    
    EffectLibrary:Play('Indicator', Caster, {Text = 'DODGE', Critical = true})
    EffectLibrary:Play("Glow", Caster)
end