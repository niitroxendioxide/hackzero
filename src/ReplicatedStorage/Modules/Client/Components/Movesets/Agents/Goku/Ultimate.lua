--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)
local Cutscenes = require(Client.Libraries.Cutscenes)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass)
    print('Hi?')
    Cutscenes:Start("GokuSSJ", Agent)

    Ability:Begin(Agent, {
        {0, function()
            Agent:SwitchState('Attacking', 1, true)
        end},
    })
end

return Ability