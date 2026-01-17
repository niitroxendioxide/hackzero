--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Context: { read Target: any })
	local function HitEnemy()
		Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.create(9.5, 7, 14.5), function(Target)
			Ability:Hit(Caster, Target, {Effect_Data = {
				Highlight = true,
				Audio = {
					Id = {8595980577},
					Volume = 0.5,
				}
			},})
		end)
	end

    local Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, 'Goku.Abilities.M1.SuperGodFist', {
				Fade = .1,
				Active_Time = Attack_State_Time,
			})

			Caster:SwitchState('Attacking', Attack_State_Time, true)
			Ability:Effect("Goku_SuperGodFist", Caster, 'Charge')
		end},

		{0.35, function()
			Caster:ImpulseForward(60, 0.75)
		end},

		{0.36, 0.75, function()
			if Context and Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{0.4, HitEnemy},
		{0.5, HitEnemy},
		{0.6, HitEnemy},

		{0.45, function()
			Ability:Effect("Goku_SuperGodFist", Caster, 'Attack')
		end},
	})
end

return Ability