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

function Ability:Play(Caster: Types.AgentClass, _, _, Context)
	local Anim = Context.IsCancel and 'Back' or 'Forth'
	if not Context.IsCancel then
		Ability:Effect("Dodge_VFX", Caster)
	else
		Ability:Effect("Cancel", Caster)
	end

	local Sign = Context.IsCancel and -1 or 1;
	local IsOffCooldown = os.clock() - (Ability:Get(Caster, "LastShotTime") or 0) > Ability:FromData('Fall_Back_Cooldown');
	Ability:Save(Caster, "LastShotTime", os.clock())

	---
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			local AnimObj = Animation:GetMovementAnim(Caster.Name, 'Dash'..Anim)
			Ability:PlayAnimation(Caster, AnimObj, {Active_Time = 0.4, State = 'Dashing', Speed = 1, Weight = 50})

			Caster:SwitchState('Dashing', .35)
			Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
		end},
	}, true)

	if IsOffCooldown and Sign == -1 then
		for _, Time in Ability:FromData('Shot_Times') do
			Sequence:Add(Time, function()
				Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Repeat', {Fade = .05})

				Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
					Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}, NoCameraShake = true, NoHitStop = true})
				end)
			end)
		end
	end

	Sequence:Start()
end

return Ability
