--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass): ()
	--
	Ability:Begin(Caster, {
        {0, function()
            print("Assist attack!")
        end},

        {0.2, function()
            Ability:ForOtherAgents(Caster, function(Agent, Data)
                if Data.IsNext then
                    print(Data.IsNext, Agent.Name)
                    for _, Buff in Ability:FromData('AssistBuff') do
                        Agent:AddEffect(Buff)
                    end
                end
            end)
        end},
    })
end

return Ability
