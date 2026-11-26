--[[
    Gomu Gomu no Axe - Luffy winds up for a moment, then smashes the ground a few studs in front.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	const Hit = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))
	const Attack_State_Time = Ability:FromData("Attack_State_Time")
	const Smash_Time = Ability:FromData("Smash_Time")
	const Smash_Offset = Ability:FromData("Smash_Offset")
	const Smash_Size = Ability:FromData("Smash_Size")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context and Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Smash_Time, function()
			Ability:CreateHitbox(Caster, Smash_Offset, Smash_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, Hit)
			end)
		end},
	})
end

return Ability
