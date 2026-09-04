--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local KakashiController = require(script.Parent.KakashiGameplayController)

--
local Ability = AbilityClass.new()

const function TryEnterLightningMode(Caster: Types.ServerAgent): boolean
	Ability:Save(Caster, 'SkillHeld', true)

	const Hold_Time = Ability:FromData('Lightning_Mode_Hold_Time')
	const HoldStart = os.clock();
		
	Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Hold_Time)

	while (Ability:Get(Caster, "SkillHeld") == true) do
		const Was_Held = (os.clock() - HoldStart) >= Hold_Time

		if Was_Held then
			KakashiController:EnterLightningMode(Caster, Ability:FromData('Lightning_Mode_Time'))

			return true
		elseif not KakashiController:IsReady(Caster) then
			break;
		end

		task.wait()
	end

	return false
end

function Ability:Play(Caster: Types.ServerAgent, _, State, Ctx): ()
	if State == 'Release' then
		Ability:Save(Caster, 'SkillHeld', false)

		return
	elseif KakashiController:IsReady(Caster) then
		TryEnterLightningMode(Caster);
	end

	local M1_Count = Ctx.M1_Count
	if not(M1_Count) then
		return;
	end

	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Table.CopyDeep(Ability:FromData("Hit"))

	const In_Lightning_Mode = KakashiController:IsLightningMode(Caster)
	const Electric_Steps = Ability:FromData('Lightning_Mode_Steps')
	const Electric_Hit = Ability:FromData('Lightning_Mode_Hit')
	const Daze_Shred_Time = Ability:FromData('Lightning_Mode_Daze_Shred_Time')

	local Sequence = Ability:Begin(Caster, {}, true)

	local AttackData = Ability:FromData("Attack_Data")
	for Step = M1_Count, M1_Count + 1, 0.1 do
		local Tick = AttackData[Step];
		if not Tick then
			break
		end

		local Size = vector.create(7, 5, 7)
		local Offset = vector.create(0, 0, -4)

		if Step > 2 and M1_Count == 2 then
			Size = vector.create(12, 5, 7)
		end

		const Is_Electric_Step = In_Lightning_Mode and Electric_Steps[Step] == true

		Ability:UseAttackData(Sequence, Caster, Tick, {
			Size = Size,
			Offset = Offset,
			Hit_Function = function(Target)
				HitData.Damage = Ability:FromData("Damage", Step, SkillLevel)
				HitData.Daze = Ability:FromData("Daze", Step, SkillLevel)

				if Is_Electric_Step then
					HitData.Affliction = Electric_Hit.Affliction
					HitData.Affliction_Buildup = Electric_Hit.Affliction_Buildup
				end

				Ability:Hit(Caster, Target, HitData)

				if Is_Electric_Step then
					KakashiController:ShredResistance(Target, Daze_Shred_Time)
				elseif HitData.Affliction == 'Electric' then
					KakashiController:AddCharge(Caster, 1)
				end
			end
		})
	end

	Sequence:Start()
end

return Ability
