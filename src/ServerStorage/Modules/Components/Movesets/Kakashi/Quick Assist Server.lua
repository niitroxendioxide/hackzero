--[[
    ROUGH DRAFT - structure, timings and damage wiring are in place; animations and VFX are
    referenced by name and still need assets.

    Default:        'Raikiri: Issen' - subs in dashing forward, hits the first target with a discharge.
    Lightning Mode: Kagebunshin split, then two 'Raiton: Raiju Tsuiga' dogs that paralyze, stun and
                    shred electric resistance.
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

--[[ Default variant: dash in, hit the first thing in front. ]]
const function RaikiriIssen(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const HitData = Table.CopyDeep(Ability:FromData('Hit', nil, SkillLevel))
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Dash_Time = Ability:FromData('Dash_Time')
	const Dash_Power = Ability:FromData('Dash_Power')
	const Hitbox_Size = Ability:FromData('Hitbox_Size')
	const Hitbox_Offset = Ability:FromData('Hitbox_Offset')

	local Single_Hit = false;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Caster:Walk(Dash_Time, Dash_Power, true)
		end},

		{Startup_Time, Startup_Time + Dash_Time, function()
			if Single_Hit then
				return
			end

			Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
				if Single_Hit then
					return
				end

				Single_Hit = true;

				Ability:Hit(Caster, Enemy, HitData)
				KakashiController:AddCharge(Caster, 1)
			end)
		end},
	})
end

--[[ Lightning Mode variant: two dogs, one per shadow clone. ]]
const function RaijuTsuigaPair(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const DogHit = Table.CopyDeep(Ability:FromData('Dog_Hit', nil, SkillLevel))
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Paralyze_Time = Ability:FromData('Paralyze_Time')

	const Dog_Count = Ability:FromData('Dog_Count')
	const Dog_Speed = Ability:FromData('Dog_Speed')
	const Dog_Max_Time = Ability:FromData('Dog_Max_Time')
	const Dog_Size = Ability:FromData('Dog_Size')
	const Dog_Spread = Ability:FromData('Dog_Spread')
	const Dog_Daze_Shred_Time = Ability:FromData('Dog_Resistance_Shred_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			for Index = 1, Dog_Count do
				const Side = (Index % 2 == 0) and 1 or -1
				const Origin = Caster:GetPivot() * CFrame.new(Dog_Spread * Side, -1, -3)
				const Hit_List = {}

				local Projectile = Ability:CreateMovingHitbox(Caster, Origin, Dog_Size, Dog_Speed, Dog_Max_Time, function(Enemy)
					if Hit_List[Enemy] then
						return
					end

					Hit_List[Enemy] = true

					Ability:Hit(Caster, Enemy, DogHit)
					KakashiController:Paralyze(Enemy, Paralyze_Time, Caster)
					KakashiController:ShredResistance(Enemy, Dog_Daze_Shred_Time)
				end)

				Projectile:Debug()
			end

			KakashiController:AddCharge(Caster, 1)
		end},
	})
end

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	if KakashiController:IsLightningMode(Caster) then
		RaijuTsuigaPair(Caster, Context)
	else
		RaikiriIssen(Caster, Context)
	end
end

return Ability
