--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass): ()

    local AttackTime = Ability:FromData('Attack_State_Time')

    Ability:Begin(Agent, {
        {0, function()
            Agent:SwitchState('Attacking', AttackTime)
        end,},

        {.2, function()
            Ability:Effect('Kamehameha_Beam', Agent)
        end}
    })
end

return Ability