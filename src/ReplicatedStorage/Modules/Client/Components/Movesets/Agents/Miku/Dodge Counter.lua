--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context)
	local Attack_Time = Ability:FromData('Attack_State_Time')

	local Sequence = Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, 'Miku.Abilities.Counter.Default', {})
			Ability:Effect("Miku_ToggleLeek", Caster, "Enable", 2)
		end,},

		{0, 1.1, function()
			Caster:LookAtTarget(Context.Target)
		end},
	
		{.667, function()
			Ability:Effect("Miku_CounterOrb", Caster, CFrame.new(-0.339, 2.503, 0.704), CFrame.new(-0.331, 0.341, -4.5), 0.1)
		end},

		{0.767, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.one * 10, function(Enemy)
				Ability:Hit(Caster, Enemy, {
					EffectData = {
						Highlight = true,
						HighlightColor = Color3.fromRGB(26, 255, 228),
						HueShift = 130,
					}
				})
			end)
		end},

		{1.083, function()
			Ability:Effect("Miku_CounterOrb", Caster, CFrame.new(-0.339, 2.503, 0.704), CFrame.new(-0.331, 0.341, -13), 0.1)
		end},

		{1.183, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.one * 10, function(Enemy)
				Ability:Hit(Caster, Enemy, {
					EffectData = {
						Highlight = true,
						HighlightColor = Color3.fromRGB(26, 255, 228),
						HueShift = 130,
					}
				})
			end)
		end}

	}, true)

	Sequence:Start()
end

return Ability