--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Caster, {
		{0, function(_)
			Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Special.Default', {
				Fade = .1,
				Active_Time = Attack_Time + 0.25,
			})

			Caster:SwitchState('Attacking', Attack_Time)
		end,},

		{2/60, function()
			Ability:EffectSerial("Chihiro_Kuro", Caster, 'Charge')
		end},

		{.41, function()
			local Targets = {};
			local Hits = {};

			Ability:EffectSerial("Chihiro_Kuro", Caster, 'Attack', function(Target)
				if Targets[Target:GetId()] or (Hits[Target] or 0) >= 4 then
					return
				end

				Targets[Target:GetId()] = true
				task.delay(1/4, function()
					Targets[Target:GetId()] = false
				end)

				Hits[Target:GetId()] = (Hits[Target:GetId()] or 0) + 1

				Ability:Hit(Caster, Target, {EffectData = Ability:FromData("HitEffectData")})
			end)
		end},
	})
end

return Ability