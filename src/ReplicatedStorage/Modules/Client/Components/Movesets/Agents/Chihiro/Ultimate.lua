--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass)
    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', Ability:FromData("Attack_State_Time"), true)

            Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Ultimate.Default', { 
                Fade = 0.1,
            })
        end},
    })
end

return Ability