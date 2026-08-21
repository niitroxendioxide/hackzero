--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(Client.Libraries.Animation)
local Statics = require(Shared.Database.Statics)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass, _, State, Context)
	local Anim = Context.IsCancel and 'Back' or 'Forth'
	if not Context.IsCancel then
		Ability:Effect("Dodge_VFX", Caster)
	else
		Ability:Effect("Cancel", Caster)
	end

	local AnimObj = Animation:GetMovementAnim(Caster.Name, 'Dash'..Anim)
	Ability:PlayAnimation(Caster, AnimObj, {Active_Time = 0.4, State = 'Dashing', Speed = 1, Weight = 50})
	Caster:SwitchState('Dashing', .35)
	
	local Sign = Context.IsCancel and -1 or 1;
	
	Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
end

return Ability
