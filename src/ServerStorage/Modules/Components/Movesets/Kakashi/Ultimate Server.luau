--[[
    ROUGH DRAFT - structure, timings and damage wiring are in place; animations and VFX are
    referenced by name and still need assets.

    'Raikiri: Sōraishin' - dash forward, launch everything in a small area on first contact, hit them
    in a zig-zag mid-air, then slam them all down with a final Raikiri.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local KakashiController = require(script.Parent.KakashiGameplayController)

--
local Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.ServerAgent)
	Caster:Walk(0, 1)
end)

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const LaunchData = Table.CopyDeep(Ability:FromData('Launch_Hit', nil, SkillLevel))
	const AirborneData = Table.CopyDeep(Ability:FromData('Airborne_Hit', nil, SkillLevel))
	const SlamData = Table.CopyDeep(Ability:FromData('Slam_Hit', nil, SkillLevel))

	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Dash_Hitbox_Size = Ability:FromData('Dash_Hitbox_Size')

	const Launch_Radius = Ability:FromData('Launch_Radius')
	const Launch_Time = Ability:FromData('Launch_Time')
	const Airborne_Hit_Frequency = Ability:FromData('Airborne_Hit_Frequency')
	const Slam_Time = Ability:FromData('Slam_Time')
	const Slam_Radius = Ability:FromData('Slam_Radius')

	-- Everything caught by the opening dash; the rest of the ult only touches these.
	const Caught = {}
	local Connected = false;
	local LastHit = os.clock();

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Caster:AddTag('Invulnerability', Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Caster:Walk(Dash_Time, Dash_Power, true)
		end},

		{0, Dash_Time, function()
			if Connected then
				return
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -15), Dash_Hitbox_Size, function(Enemy)
				if Connected then
					return
				end

				Connected = true;

				Ability:CreateHitbox(Caster, vector.zero, vector.create(Launch_Radius, 14, Launch_Radius), function(Caught_Enemy)
					if Caught[Caught_Enemy] then
						return
					end

					Caught[Caught_Enemy] = true

					Ability:Hit(Caster, Caught_Enemy, LaunchData)
				end)
			end)
		end},

		{Launch_Time, Launch_Time + Slam_Time, function()
			if not Connected then
				return
			end

			if (os.clock() - LastHit) > Airborne_Hit_Frequency then
				LastHit = os.clock()
				for Enemy in Caught do
					Ability:Hit(Caster, Enemy, AirborneData)
				end
			end
		end},

		{Launch_Time + Slam_Time, function()
			if not Connected then
				return
			end

			-- Final Raikiri: everything caught gets driven back into the ground.
			for Enemy in Caught do
				Ability:Hit(Caster, Enemy, SlamData)
			end

			Ability:CreateHitbox(Caster, vector.zero, vector.create(Slam_Radius, 16, Slam_Radius), function(Enemy)
				if Caught[Enemy] then
					return
				end

				Ability:Hit(Caster, Enemy, SlamData)
			end)

			KakashiController:AddCharge(Caster, 2)
		end},
	})
end

return Ability
