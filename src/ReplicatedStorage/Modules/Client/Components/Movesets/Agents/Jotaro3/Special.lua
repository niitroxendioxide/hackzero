--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local AgentTypes = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: AgentTypes.AgentClass, Binding: string, State: string)

    Ability:Begin(Caster, {
        {0, function()

        end},

        {0.25, function()

        end},
    })

end

return Ability
