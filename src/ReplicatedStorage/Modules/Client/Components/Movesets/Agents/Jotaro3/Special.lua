--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local AgentTypes = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: AgentTypes.AgentClass, Binding: string, State: string)

end

return Ability
