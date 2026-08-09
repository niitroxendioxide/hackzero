--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.EnemyClass)
	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local HitboxSize = Ability:FromData('Hitbox_Size')
	local HitboxOffset = Ability:FromData('Hitbox_Offset')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			--[[Ability:PlayAnimation(Enemy, 'Chihiro.Abilities.M1.1', {
				Speed = Ability:FromData('Animation_Speed'), 
				Fade = .1,
				Active_Time = Attack_Time,
			})]]
		end,},

		{0.22, function()
			Ability:Effect("Slash", Caster, Random.new():NextNumber(-70, 70), nil, math.random(1, 2) == 1)
		end},

		{.4, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Target: Types.EnemyClass)  
				Ability:Hit(Caster, Target, {NoAnim = true})
			end)
		end},


	})
end

return Ability