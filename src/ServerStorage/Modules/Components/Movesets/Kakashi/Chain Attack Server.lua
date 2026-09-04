--[[
    ROUGH DRAFT - structure, timings and damage wiring are in place; animations and VFX are
    referenced by name and still need assets.

    'Raikiri: Denko Rensen' - Kakashi subs in and cuts through the target in a zig-zag, ending on a
    heavier final pass.
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
	const HitData = Table.CopyDeep(Ability:FromData('Hit', nil, SkillLevel))
	const FinalHitData = Table.CopyDeep(Ability:FromData('Final_Hit', nil, SkillLevel))

	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dash_Count = Ability:FromData('Dash_Count')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')

	--[[
		The zig-zag itself is carried by the animation and the VFX, so this only has to walk
		forward and land a hit per pass - no CFrame repositioning.
	]]
	const Total_Time = Dash_Count * Dash_Time
	local LastHit = 0;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Caster:Walk(Total_Time, Dash_Power, true)
		end},

		{Startup_Time, Startup_Time + Total_Time, function()
			if (os.clock() - LastHit) < Dash_Time then
				return
			end

			LastHit = os.clock()

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},

		{Startup_Time + Total_Time, function()
			-- Heavier closing pass.
			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, FinalHitData)
			end)

			KakashiController:AddCharge(Caster, 1)
		end},
	})
end

return Ability
