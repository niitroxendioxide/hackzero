--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Sasuke.Abilities.Counter.Default', {
				Active_Time = Attack_Time + .25,
			})
		end},

		{0.45, function()
			Ability:Effect("Sasuke_Kunais", Caster)

			for i = -1, 1 do
				local Offset = Vector3.new(math.sin(math.rad(i * 35)) * 15, 0, math.cos(math.rad(i * 33)) * -4)
				Ability:CreateHitbox(Caster, Offset, vector.create(9, 9, 9), function(Enemy)  
					Ability:Hit(Caster, Enemy, {
						EffectData = {
							Highlight = true,
						}
					})
				end)
			end
		end},

		{0.85, function()
			Caster:Walk(0.25)
		end},

		{1.1, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(8, 8, 8), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					EffectData = {
						Highlight = true,
					}
				})
			end)
		end}
	})
end

return Ability
