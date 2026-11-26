--[[
    Gomu Gomu no Axe - client half. Wind-up, then a big smash a few studs in front.
    TODO: animation (none hooked up yet).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Cleanup = Ability:Get(Caster, 'M1_Cleanup')
	if Cleanup then
		Cleanup()
	end

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
			Ability:Effect("Luffy_Axe", Caster:GetPivot() * CFrame.new(Smash_Offset))

			Ability:CreateHitbox(Caster, Smash_Offset, Smash_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
			end)
		end},
	})
end

return Ability
