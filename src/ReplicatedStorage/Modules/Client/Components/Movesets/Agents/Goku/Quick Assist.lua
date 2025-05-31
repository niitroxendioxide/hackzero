--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass): ()
    Ability:Begin(Agent, {
        {.15, function()
            Ability:Effect('Saiyan_Skill_1', Agent, 'Charge')
        end},

        {.5, function()
            Ability:Effect('Saiyan_Skill_1', Agent, 'Shoot')
        end}
    })
end

return Ability