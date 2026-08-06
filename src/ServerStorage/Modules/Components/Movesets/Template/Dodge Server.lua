--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, _, _, Context): ()
	--
	local Sign = Context.IsCancel and -1 or 1;

	Caster:SwitchState('Dashing', .275)
	Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
end

return Ability
