--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, ctx)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")
	local HitboxSize = Ability:FromData("HitboxSize")
	local HitboxOffset = Ability:FromData("HitboxOffset")
	local CloneAnim = Animation:GetAnim('Characters.Naruto.Abilities.Counter.CloneKick')
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Naruto.Abilities.M1.4', {
				Active_Time = Attack_Time + .25,
			})


			---
			Caster:Walk(0.25, 0.45)
			Ability:Effect("Naruto_Clone", Caster, 1, CFrame.new(HitboxOffset + vector.create(0, 0, 3.5)), {Object = CloneAnim, Weight = 1, Speed = 0.85, Follow = true})
		end},

		{0, 0.3, function()
			Caster:LookAtTarget(ctx.Target)
		end},

		{0.3, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy)
				Ability:Hit(Caster, Enemy, {Track = 'Characters.Naruto.Abilities.M1.Victim_1', EffectData = {Highlight = true}})
			end)
		end}
	})
end

return Ability
