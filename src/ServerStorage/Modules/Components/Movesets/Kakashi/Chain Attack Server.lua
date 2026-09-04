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
	const Side_Offset = Ability:FromData('Side_Offset')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			--[[
				Each pass reappears on the opposite side of the target and cuts back through it.
				Teleporting rather than running keeps the server in step with the client's zig-zag.
			]]
			for Index = 1, Dash_Count do
				const Side = (Index % 2 == 0) and 1 or -1
				const IsFinal = (Index == Dash_Count)

				if Context.Target then
					const TargetPivot = Context.Target:GetPivot()

					Caster:PivotTo(TargetPivot * CFrame.new(Side_Offset * Side, 0, 6))
					Caster:LookAtTarget(Context.Target)
				end

				Caster:Walk(Dash_Time, Dash_Power, true)

				Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
					Ability:Hit(Caster, Enemy, IsFinal and FinalHitData or HitData)
				end)

				task.wait(Dash_Time)
			end

			KakashiController:AddCharge(Caster, 1)
		end},
	})
end

return Ability
