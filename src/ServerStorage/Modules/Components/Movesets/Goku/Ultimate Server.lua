--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local EffectData = Ability:FromData("SSBuff")

	Ability:Begin(Caster, {
        {0, function()
            for _, Effect in EffectData do
                Caster:AddEffect(Effect)
            end

            Caster:SwitchState('Attacking', 1, true)
            Caster:AddTag('Invulnerability', 1)
        end},
    })
end

return Ability
