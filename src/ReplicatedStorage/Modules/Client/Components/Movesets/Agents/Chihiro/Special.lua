--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Caster)
	Ability:Increase(Caster, "CurSkillCount", {Limit = 3})
	Ability:PushToContextBuffer(Ability:Get(Caster, "CurSkillCount"))
end)

function Ability:Play(Caster)
	local Count = Ability:Get(Caster, "CurSkillCount")

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState("Attacking", Attack_Time)
			Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Special.Base_' .. Count, {
				Active_Time = Attack_Time,
			})

			if Count == 2 then
				Caster:Walk(0.275, -0.75)
				Ability:Effect("Goku_M1_5", Caster, 0.2, true)
			end
		end,},

		{0.217, function()
			if Count == 1 then
				Caster:Walk(0.15, 1.15)
				Ability:EffectSerial("Slash", Caster, -50, nil, false)

				Ability:CreateHitbox(Caster, vector.create(0, 0, -4.5), vector.create(5, 5, 9), function(Enemy)
					Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
				end)
			end
		end},

		{0.3, function()
			if Count == 2 then
				Caster:Walk(0.15, 1.15)
			end
		end},

		{0.27, function()
			if Count == 3 then
				Caster:Walk(0.2, 1.2)
			end
		end},

		{0.417, function()
			if Count == 2 then
				Ability:EffectSerial("Slash", Caster, -85, nil, true)

				Ability:CreateHitbox(Caster, vector.create(0, 0, -4.5), vector.create(5, 5, 9), function(Enemy)
					Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
				end)
			end
		end},

		{0.317, function()
			if Count == 3 then
				Ability:Effect("Hit", Caster, {Emitter = "FrontAttack", Offset = CFrame.new(0.128, -0.692, -5.348), Weld = true})

				Ability:CreateHitbox(Caster, vector.create(0, 0, -6), vector.create(3, 3, 12), function(Enemy)
					Ability:Hit(Caster, Enemy, {EffectData = {Highlight = true}})
				end)
			end
		end}
	})
end

return Ability