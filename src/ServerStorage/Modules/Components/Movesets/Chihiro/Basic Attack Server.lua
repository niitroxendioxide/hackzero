--
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services
local Libraries = ServerStorage.Modules.Libraries

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Types = require(Shared.Types.Abilities)
local DamageLibrary = require(Libraries.Damage)
local AbilityClass = require(Classes.Combat.ServerAbility)
local AbilityService = require(Services.Combat.AbilityService)
local ChihiroGameplayController = require(script.Parent.ChihiroGameplayController)

--
local Ability = AbilityClass.new()

local function HandleParryAbility(Caster)
	Ability:Save(Caster, "Holding", true)
	Caster:SwitchState("Attacking", 9e12)

	local Activated = false
	local Started = os.clock()
	local ParryId = HttpService:GenerateGUID(false)

	while (Ability:Get(Caster, "Holding") == true) do
		if not Caster:IsActive() then
			break
		end

		if not Activated and (os.clock() - Started) >= 0.2 then
			Activated = true

			Caster:AddTag('StunImmunity')
			AbilityService:ConnectDamageHook(Caster, ParryId, function(Perpetrator, HitData: Types.HitEnemyData): Types.HitEnemyData
				local TotalDamageDealt = DamageLibrary:CalculateRawAttackDamage(Perpetrator, Caster, HitData.Damage)
				ChihiroGameplayController:AddUltimateCharge(Caster, TotalDamageDealt, 10_000)

				Ability:Effect("Chihiro_Parried", {Caster}, true)

				HitData.Damage *= 0.25

				return HitData
			end)
		end

		task.wait()
	end

	if Activated then
		Caster:SwitchState("Attacking", 0.25)
		Caster:RemoveTag('StunImmunity')
		AbilityService:DisconnectDamageHook(Caster, ParryId)

		return true
	end
	
	Caster:SwitchState("Attacking", 0)

	return true
end

function Ability:Play(Caster: Types.Caster, _, State, Context:{ read M1_Count: number }): ()
	if State == 'End' then
		Ability:Save(Caster, "Holding", false)

		return
	else
		local ShouldContinue = HandleParryAbility(Caster)

		if not ShouldContinue then
			return
		end
	end
	
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end
	
	--local M1_Count = Ability:Get(Caster, 'Count')
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local Sequence = Ability:Begin(Caster, {})
	
	for HitCount = M1_Count, M1_Count + 1, 0.1 do
		local AttackData = Ability:FromData("Attack_Data", HitCount)
		if AttackData == nil or AttackData == 0 then
			break
		end

		Ability:UseAttackData(Sequence, Caster, AttackData, {
			Size = Vector3.new(9, 9, 14),
			Offset = Vector3.new(0, 0, -7),
			Hit_Function = function(Target: Types.Target)
				Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage', HitCount, SkillLevel),
					Daze = Ability:FromData('Daze', HitCount, SkillLevel),
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', HitCount, SkillLevel),
					Affliction = 'Physical',
					HitType = 'Slash',
					Stun = 0.25,
					Knockback = {
						vector.create(0, 0, 1),
						11,
						0.2
					}
				})
			end
		})

	end

	Sequence:Start()
end

return Ability
