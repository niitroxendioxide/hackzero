--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent, _, _State, Context)
	const Attack_State_Time = Ability:FromData("Attack_State_Time")
	const Hitbox_Size = Ability:FromData("Geass_Area")

	Ability:Begin(Caster, {
		{0, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Geass', {
				Fade = .1,
			})

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.35, function()
			const Center = Context.Target:GetPivot()
			const Offset = (Caster:GetPivot():ToObjectSpace(Center)).Position;
			
			Ability:CreateHitbox(Caster, Offset, Hitbox_Size, function(Enemy)
				Ability:Effect("Lelouch_GeassAffect", Context.Target:GetId())
			end)
		end},

		{0.35, 0.55, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end}
	})
end

return Ability
