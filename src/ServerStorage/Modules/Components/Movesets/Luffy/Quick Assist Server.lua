--[[
    Gomu Gomu no Rocket - Luffy pulls back, then launches forward with enemy collisions off.
    Anyone hit during the launch is grabbed and carried in front of him, then released with a
    knockback hit when the launch ends.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local GrabService = require(ServerStorage.Modules.Services.Combat.GrabService)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
const COLLISION_PRIORITY = 5
local Ability = AbilityClass.new()

-- Carried maps Enemy -> true while held, false once let go (so nobody gets grabbed twice).
const function ReleaseAll(Caster: Types.ServerAgent): { any }
	const Carried = Ability:Get(Caster, 'Carried') or {}

	const Released = {}
	for Enemy, Held in Carried do
		if Held then
			Carried[Enemy] = false
			GrabService:ForceStopGrab(Enemy)
			table.insert(Released, Enemy)
		end
	end

	return Released
end

Ability:OnCancel(function(Caster: Types.ServerAgent)
	Caster:Walk(0, 1)
	ReleaseAll(Caster)
	Caster:SetEnemyCollisionState(true, COLLISION_PRIORITY)
end)

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	const SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	const Hit = Ability:FromData("Hit", nil, SkillLevel)
	const Release_Hit = Ability:FromData("Release_Hit", nil, SkillLevel)

	const Attack_State_Time = Ability:FromData("Attack_State_Time")
	const Pull_Time = Ability:FromData("Pull_Time")
	const Pull_Power = Ability:FromData("Pull_Power")
	const Launch_Time = Ability:FromData("Launch_Time")
	const Launch_Duration = Ability:FromData("Launch_Duration")
	const Launch_Power = Ability:FromData("Launch_Power")
	const Hitbox_Size = Ability:FromData("Hitbox_Size")
	const Hitbox_Offset = Ability:FromData("Hitbox_Offset")
	const Carry_Offset = Ability:FromData("Carry_Offset")

	const Launch_End = Launch_Time + Launch_Duration
	const Carried = {}
	local Launch_Over = false
	Ability:Save(Caster, 'Carried', Carried)

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
				if Launch_Over or Carried[Enemy] ~= nil then
					return
				end

				-- Grab lasts a little past the launch as a safety net; the release below ends it.
				if GrabService:GrabEnemy(Caster, Enemy, Launch_Duration + 0.5, Carry_Offset) then
					Carried[Enemy] = true
					Ability:Hit(Caster, Enemy, Hit)
				end
			end)
		end},

		{Launch_End, function()
			Launch_Over = true

			for _, Enemy in ReleaseAll(Caster) do
				Ability:Hit(Caster, Enemy, Release_Hit)
			end
		end},
	}, true)

	Sequence:After(function()
		ReleaseAll(Caster)
		Caster:SetEnemyCollisionState(true, COLLISION_PRIORITY)
	end)

	Sequence:Start()
end

return Ability
