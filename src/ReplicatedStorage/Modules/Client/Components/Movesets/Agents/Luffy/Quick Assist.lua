--[[
    Gomu Gomu no Rocket - client half. Pull back, launch forward through enemies, carry whoever
    is hit (the grab itself is replicated from the server), release at the end of the launch.
    TODO: animation (none hooked up yet).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const COLLISION_PRIORITY = 5
const HIT_EFFECT = {NoHitStop = true, EffectData = {Highlight = true}}

local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Caster:Walk(0, 1)
	Caster:SetEnemyCollisionState(true, COLLISION_PRIORITY)
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Cleanup = Ability:Get(Caster, 'M1_Cleanup')
	if Cleanup then
		Cleanup()
	end

	const Attack_State_Time = Ability:FromData("Attack_State_Time")
	const Pull_Time = Ability:FromData("Pull_Time")
	const Pull_Power = Ability:FromData("Pull_Power")
	const Launch_Time = Ability:FromData("Launch_Time")
	const Launch_Duration = Ability:FromData("Launch_Duration")
	const Launch_Power = Ability:FromData("Launch_Power")
	const Hitbox_Size = Ability:FromData("Hitbox_Size")
	const Hitbox_Offset = Ability:FromData("Hitbox_Offset")

	const Launch_End = Launch_Time + Launch_Duration
	const Carried = {}
	local Launch_Over = false

	const Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Caster:SetEnemyCollisionState(false, COLLISION_PRIORITY)

			if Context and Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Caster:Walk(Pull_Time, Pull_Power)
		end},

		{Launch_Time, function()
			Caster:Walk(Launch_Duration, Launch_Power, true)
		end},

		{Launch_Time, Launch_End, function()
			Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
				if Launch_Over or Carried[Enemy] then
					return
				end

				Carried[Enemy] = true
				Ability:Hit(Caster, Enemy, HIT_EFFECT)
			end)
		end},

		{Launch_End, function()
			Launch_Over = true

			for Enemy in Carried do
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
			end
		end},
	}, true)

	Sequence:After(function()
		Caster:SetEnemyCollisionState(true, COLLISION_PRIORITY)
	end)

	Sequence:Start()
end

return Ability
