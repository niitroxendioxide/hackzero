--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local SasukeGameplayController = require("./SasukeGameplayController")

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local BaseHitData = Table.CopyDeep(Ability:FromData("Hit"))
	local Attack_Data = Ability:FromData("Attack_Data")

	local Sequence = Ability:Begin(Caster, {
		{0, function()
		end},
	}, true)

	for i = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[i]
		if not TickData then
			break
		end

		BaseHitData.Damage = Ability:FromData("Damage", i, SkillLevel)
		BaseHitData.Daze = Ability:FromData("Daze", i, SkillLevel)

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = Ability:FromData("HitboxSize"),
			Offset = Ability:FromData("HitboxOffset"),

			Hit_Function = function(Target)
				if i == 2.1 then
					BaseHitData.Knockback = {
						vector.create(0, 0, 1),
						36,
						0.2,
					}
				end

				Ability:Hit(Caster, Target, BaseHitData)
			end
		})

		if i == 3.1 then
			Sequence:Add(1, function()
				local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot(), vector.create(5, 5), 75, 1, function(Target)
					SasukeGameplayController:ConnectThread(Target, Caster)
					Object:Destroy()

					Ability:Hit(Caster, Target, BaseHitData)
				end)
			end)
		end
	end

	Sequence:Start()
end

return Ability
