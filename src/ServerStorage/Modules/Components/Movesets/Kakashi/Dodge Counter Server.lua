--[[
    ROUGH DRAFT - structure, timings and damage wiring are in place; animations and VFX are
    referenced by name and still need assets.

    Default:        'Raiton: Raiju Tsuiga' - a lightning dog runs forward and paralyzes what it hits.
    Lightning Mode: 'Shishi Rendan' launches the target, then a 'Raikiri' ground slam detonates.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local GrabService = require(ServerStorage.Modules.Services.Combat.GrabService)
local Table = require(Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local KakashiController = require(script.Parent.KakashiGameplayController)

--
const RAIJU_ID =  "RaijuTsuigaDodgeCounter"
local Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.ServerAgent)
	Caster:Walk(0, 1)
end)

--[[ Default variant: send a lightning dog forward. ]]
const function RaijuTsuiga(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const HitData = Table.CopyDeep(Ability:FromData('Hit', nil, SkillLevel))
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Startup_Time')
	const Paralyze_Time = Ability:FromData('Paralyze_Time')

	const Dog_Speed = Ability:FromData('Dog_Speed')
	const Dog_Max_Time = Ability:FromData('Dog_Max_Time')
	const Dog_Size = Ability:FromData('Dog_Size')

	const Hit_List = {}

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			const Origin = Caster:GetPivot()
			local HasHit = false;

			Ability:CreateMovingHitbox(Caster, Origin, Dog_Size, Dog_Speed, Dog_Max_Time, function(Enemy)
				if Hit_List[Enemy] then
					return
				end

				if not HasHit then
					HasHit = true
					Ability:Effect('Kakashi_Raiju', {Caster, 'DeleteEXP', RAIJU_ID, Enemy:GetId()}, true)
				end

				Hit_List[Enemy] = true

				Ability:Hit(Caster, Enemy, HitData)
				KakashiController:Paralyze(Enemy, Paralyze_Time, Caster)
				KakashiController:AddCharge(Caster, 1)
			end)
		end},
	})
end

--[[ Lightning Mode variant: kick the target up, then slam the ground with Raikiri. ]]
const function ShishiRendan(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const KickData = Table.CopyDeep(Ability:FromData('RendanKickHit', nil, SkillLevel))
	const SlamData = Table.CopyDeep(Ability:FromData('Rendan_Slam_Hit', nil, SkillLevel))
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Startup_Time = Ability:FromData('Rendan_Startup_Time')
	const Paralyze_Time = Ability:FromData('Paralyze_Time')

	const Slam_Time = Ability:FromData('Rendan_Slam_Time')
	const Slam_Radius = Ability:FromData('Rendan_Slam_Radius')

	const Hitbox_Size = Ability:FromData('Hitbox_Size')
	const Hitbox_Offset = Ability:FromData('Hitbox_Offset')
	local HasHit = false;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Ability:CreateHitbox(Caster, Hitbox_Offset, Hitbox_Size, function(Enemy)
				const Grabbed = GrabService:GrabEnemy(Caster, Enemy, 1, CFrame.new(0, 0, -4.1))
				if Grabbed then
					HasHit = true
					Ability:Hit(Caster, Enemy, KickData)
				end
			end)
		end},

		{Slam_Time, function()
			if not HasHit then
				return;
			end

			Ability:CreateHitbox(Caster, vector.zero, vector.create(Slam_Radius, 12, Slam_Radius), function(Enemy)
				Ability:Hit(Caster, Enemy, SlamData)
				KakashiController:Paralyze(Enemy, Paralyze_Time, Caster)
			end)

			KakashiController:AddCharge(Caster, 1)
		end},

		{1.35, function()
			if not HasHit then
				return
			end

			Caster:ImpulseForward(-35, 0.5)
		end}
	})
end

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	if KakashiController:IsLightningMode(Caster) then
		ShishiRendan(Caster, Context)
	else
		RaijuTsuiga(Caster, Context)
	end
end

return Ability
