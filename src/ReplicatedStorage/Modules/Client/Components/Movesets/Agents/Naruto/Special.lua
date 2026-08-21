--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Context)
	local Attack_Time = Ability:FromData("Attack_State_Time")
	local Side = math.random(1, 2) == 1 and 1 or -1

	local Marked = {}
	local function AssignClone(Target)
		if Marked[Target] then
			return;
		end

		Marked[Target] = true
	end

	---
	local HitData = {
		NoHitStop = true,
	}

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.CloneJutsu", {Active_Time = 0.5})
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{0, 0.9, function()
			Caster:LookAtTarget(Context.Target)
		end},

		{0.15, function()
			local Object = Animation:GetAnim('Characters.Naruto.Abilities.Special.FirstHitClone' )
			local CloneOffset = CFrame.new(3.25 * Side, 0, -5) * CFrame.Angles(0, math.rad(42 * Side), 0)
			Ability:Effect('Naruto_Clone', Caster, 0.55, CloneOffset, {Object = Object, Speed = 1, NoSmokeOut = true})
		end},

		{0.65, function()
			local Object = Animation:GetAnim('Characters.Naruto.Abilities.Special.KickFlyingClone')
			local CloneOffset = CFrame.new(-1 * Side, 1.85, -5) * CFrame.Angles(0, math.rad(-7 * Side), 0)
			Ability:Effect('Naruto_Clone', Caster, 0.55, CloneOffset, {Object = Object, Speed = 1, Follow = true, NoSmokeOut = true})
		end},

		{0.4, function(self)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.create(6, 6, 6), function(Enemy: Types.EnemyClass)
				Ability:Hit(Caster, Enemy, HitData)
				AssignClone(Enemy)
			end)
		end},

		{0.9, function(self)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -8), vector.create(6, 6, 8), function(Enemy: Types.EnemyClass)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					Track = 'Characters.Naruto.Abilities.M1.Victim_3'
				})

				Ability:Effect("GroundRocksTrail", Enemy, 0.4, true)

				AssignClone(Enemy)
			end)
		end},

		{1.15, function()
			for Target in Marked do
				local AnimObject = Animation:GetAnim('Characters.Naruto.Abilities.Special.Default_SuccesfulGrab')
				Ability:Effect('Naruto_Clone', Caster, 0.55, CFrame.Angles(0, math.pi, 0), {Object = AnimObject, Speed = 1, FollowTarget = Target, NoSmokeWeld = true})

				task.delay(0.45, function()
					Ability:Hit(Caster, Target, {
						NoHitStop = true,
						EffectData = {Highlight = true},
						Track = 'Characters.Naruto.Abilities.Special.BackHitFall'
					})
				end)
			end
		end}
	})
end

return Ability
