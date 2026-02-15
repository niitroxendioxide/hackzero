--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster)

	--
	local HitRate = Ability:FromData("HitRate")
	local LastHit = os.clock()
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, "Sasuke.Abilities.Assist.Default", {})
		end,}, 

		{0.33, function()
			Ability:Effect("Sasuke_FireballBarrage", Caster)
		end},

		{0.35, 0.85, function()
			if (os.clock() - LastHit) < HitRate then
				return
			end

			LastHit = os.clock()

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), vector.create(12, 12, 16), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					EffectData = {
						Highlight = true,
					}
				})
			end)
		end}
	});
end

return Ability