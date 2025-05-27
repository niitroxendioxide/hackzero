--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass): ()
	--
	Caster:SwitchState('Dashing', .15)
	Caster:ApplyImpulse(Caster:GetPivot().LookVector * 75)
end

return Ability
