--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster)
	Ability:Effect("Naruto_FumaShuriken", Caster, true)
end)

function Ability:Play(Caster: Types.GenericClass, _, _, ctx)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")
	local HitboxSize = Ability:FromData("HitboxSize")
	local CloneAnim = Animation:GetAnim('Characters.Goku.Abilities.M1.Sledgehammer')
	
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Naruto.Abilities.Counter.ThrowShuriken', {
				Active_Time = Attack_Time + .25,
			})

			Ability:Effect("Naruto_FumaShuriken", Caster, true)
		end},

		{0, 0.3, function()
			Caster:LookAtTarget(ctx.Target)
		end},

		{0.33, function()
			local OnHit = function(Enemy: Types.EnemyClass)
				if not Enemy or not Enemy:GetModel() then
					return false
				end

				task.delay(0.45 / 1.1, function()
					local Offset = Caster:GetPivot():ToObjectSpace(Enemy:GetPivot()).Position
					Ability:CreateHitbox(Caster, Offset, HitboxSize, function(HitTarget)
						Ability:Hit(Caster, HitTarget, {
							NoCameraShake = true,
							NoHitStop = true,
							EffectData = {
								Highlight = true,
							}
						})
					end)
				end)

				Ability:Hit(Caster, Enemy, {
					NoCameraShake = true,
					NoHitStop = true,
					EffectData = {
						Highlight = true,
					}
				})

				Ability:Effect("Naruto_Clone", Caster, 1, CFrame.new(0, 1, -2.5) * CFrame.Angles(0, math.pi, 0), {Object = CloneAnim, Time = 0.55, Weight = 1, Speed = 1.1, FollowTarget = Enemy:GetModel()})

				return true
			end

			Ability:Effect("Naruto_FumaShuriken", Caster, 80, 1.25, nil, function(Enemy: Types.EnemyClass)
				OnHit(Enemy)
			end)
		end}
	})
end

return Ability
