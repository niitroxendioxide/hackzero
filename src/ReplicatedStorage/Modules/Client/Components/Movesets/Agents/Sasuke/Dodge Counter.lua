--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent,_,_, Ctx)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")
	local HitFrequency = Ability:FromData("HitFrequency")

	local Hits = {}
	local LastReloadShake = os.clock();

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Sasuke.Abilities.Counter.Default', {
				Active_Time = Attack_Time + .25,
			})
		end},

		{0, 0.45, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end
		end},

		{0.45, function()
			Ability:Effect("Sasuke_Kunais", Caster)

			for i = -1, 1 do
				local Offset = Vector3.new(math.sin(math.rad(i * 35)) * 15, 0, math.cos(math.rad(i * 33)) * -4)
				Ability:CreateHitbox(Caster, Offset, vector.create(9, 9, 9), function(Enemy)  
					Ability:Hit(Caster, Enemy, {
						NoHitStop = true,
						EffectData = {
							Highlight = true,
						}
					})
				end)
			end
		end},

		{0.85, function()
			Caster:Walk(0.25)
		end},

		{1.1, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(8, 8, 8), function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					EffectData = {
						Highlight = true,
					}
				})
			end)
		end},

		{1.6, function()
			Caster:Walk(0.7, -0.2, true)
			Ability:Effect("Sasuke_FlameThrower", Caster, true)
		end},

		{1.6, 2.3, function()
			if Ctx.Target and Ctx.Target:IsAlive() then
				Caster:LookAtTarget(Ctx.Target)
			end

			local UsedShake = false
			if (os.clock() - LastReloadShake) >= HitFrequency then
				UsedShake = true
				LastReloadShake = os.clock()
			end
			
			Ability:CreateHitbox(Caster, vector.create(0, 0, -8), vector.create(8, 8, 14), function(Enemy)
				if (Hits[Enemy] == true) then
					return
				end

				Hits[Enemy] = true;
				task.delay(HitFrequency, function()
					Hits[Enemy] = false; 
				end)

				Ability:Hit(Caster, Enemy, {NoCameraShake = not UsedShake, EffectData = {Highlight = true, HighlightColor = Color3.fromRGB(255, 82, 29)}, NoHitStop = true})
				if UsedShake then
					UsedShake = false
				end
			end)
		end},

		{2.3, function()
			Ability:Effect("Sasuke_FlameThrower", Caster, false)
		end}
	})
end

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster)
	Ability:Effect("Sasuke_FlameThrower", Caster, false)
end)

return Ability
