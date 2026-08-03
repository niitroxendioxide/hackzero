--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local ChihiroGameplayController = require(script.Parent.ChihiroGameplayController)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context): ()
	local Count = Context.Buffer[1]

	local Attack_State_Time = Ability:FromData("Attack_State_Time")
	local SkillLevel = 20 --Caster:GetSkillLevel(self.__Name)
	
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	local FishLimit = math.floor(Ability:FromData("FishMaxLimit", nil, SkillLevel + 1))

	Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState("Attacking", Attack_State_Time)

			if Count == 2 then
				Caster:Walk(0.275, -0.75)
			end
		end,},

		{0.217, function()
			if Count == 1 then
				Caster:Walk(0.15, 1.15)

				Ability:CreateHitbox(Caster, vector.create(0, 0, -4.5), vector.create(5, 5, 9), function(Enemy)
					ChihiroGameplayController:MarkSpecialHit(Caster, Enemy, FishLimit)
					Ability:Hit(Caster, Enemy, HitData)
				end)
			end
		end},

		{0.3, function()
			if Count == 2 then
				Caster:Walk(0.15, 1.15)
			end
		end},

		{0.417, function()
			if Count == 2 then
				Ability:CreateHitbox(Caster, vector.create(0, 0, -4.5), vector.create(5, 5, 9), function(Enemy)
					ChihiroGameplayController:MarkSpecialHit(Caster, Enemy, FishLimit)
					Ability:Hit(Caster, Enemy, HitData)
				end)
			end
		end}
	})

end

return Ability
