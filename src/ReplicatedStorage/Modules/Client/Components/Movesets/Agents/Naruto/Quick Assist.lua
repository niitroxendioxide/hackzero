--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, ctx)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")
	local HitboxSize = Ability:FromData("HitboxSize")
	local HitboxOffset = Ability:FromData("HitboxOffset")
	local First = Animation:GetAnim('Characters.Naruto.Abilities.Assist.Clone_1')
	local Second = Animation:GetAnim('Characters.Naruto.Abilities.Assist.Clone_2')
	local Third = Animation:GetAnim('Characters.Naruto.Abilities.Assist.Clone_3')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Naruto.Abilities.M1.4', {
				Active_Time = Attack_Time + .25,
			})

			Caster:Walk(0.25, 0.45)
		end},

		{0, 1.4, function()
			Caster:LookAtTarget(ctx.Target)
		end},

		{0.517, function()
			Ability:Effect("Naruto_Clone", Caster, .6, CFrame.new(HitboxOffset + vector.create(0, 0, 4)), {Object = First, Weight = 1, OriginOffset = CFrame.new(), CFrameTween = {0.2, 'Linear'}})
		end},

		{0.9, function()
			Ability:Effect("Naruto_Clone", Caster, .6, CFrame.new(HitboxOffset + vector.create(0, 0, 4)), {Object = Second, Weight = 1, OriginOffset = CFrame.new(2, 0, HitboxOffset.Z + 4), CFrameTween = {0.1, 'Quad', 'In'}})
		end},

		{1.4, function()
			Ability:Effect("Naruto_Clone", Caster, .6, CFrame.new(HitboxOffset + vector.create(0, 0, 4)), {Object = Third, Weight = 1, OriginOffset = CFrame.new(), CFrameTween = {0.25, 'Quad', 'In'}, Rasengan = {0.3}})
		end},

		{0.73, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
			end)
		end},

		{1.17, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
			end)
		end},

		{1.787, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy)
				Ability:Effect("Naruto_RasenganHit", Enemy, 3, 1/5)
				Ability:Effect("GroundRocksTrail", Enemy, 0.5, false)

				for i = 1, 3 do
					Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})

					task.wait(1 / 5)
				end

			end)
		end},
		
	})
end

return Ability
