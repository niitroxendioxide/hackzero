--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass, _,_, Context): ()
    local AttackTime = Ability:FromData('Attack_State_Time')
    local Enemy = Context.Enemy

    Ability:Begin(Agent, {
        {0, function()
            Agent:SwitchState('Attacking', AttackTime)
            Ability:PlayAnimation(Agent, 'Goku.Abilities.Assist.Default', {})
            
            Ability:Effect('Kamehameha_Beam', Agent, false)
        end,},

        {.35, function()
            Agent:LookAtTarget(Enemy);
            Ability:Effect('Kamehameha_Beam', Agent, true)
        end}
    })
end

return Ability