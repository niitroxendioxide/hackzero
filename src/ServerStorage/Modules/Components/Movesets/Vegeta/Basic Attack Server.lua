--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
--
local Ability = AbilityClass.new()

const function HandleKiCharge(Caster: Types.ServerAgent)
	Ability:Save(Caster, "Charging", true)

	local HasCharged = false;
	const Clock = os.clock();
	Caster:SwitchState('Attacking', 1e12)
	local SwitchedOff = false;

	while Ability:Get(Caster, "Charging") == true do
		if SwitchedOff and Caster:IsActive() then
			break
		end

		const Delta = task.wait();
		if not HasCharged and (os.clock() - Clock) > 0.3 then
			HasCharged = true; 
		end

		if not Caster:IsActive() then
			SwitchedOff = true
		end

		if HasCharged then
			Caster:UpdateMeter('Ki', Delta * 12.5)
		end
	end
	Caster:SwitchState('Idle', 0)

	return HasCharged
end

function Ability:Play(Caster: Types.ServerAgent, _, State, Context): ()
	if State == 'Release' then
		Ability:Save(Caster, "Charging", false)

		return
	else
		const Charged = HandleKiCharge(Caster)
		if Charged then return end
	end

	local M1_Count = Context.M1_Count
	if not(M1_Count) then
		return;
	end

	--local Info = CharDatabase:GetCharacterData(Caster.Name, true)
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	const Hit = Table.CopyDeep(Ability:FromData("Hit"))
	const Damage = Ability:FromData("Damages", M1_Count, SkillLevel)
	const Daze = Ability:FromData("Dazes", M1_Count, SkillLevel)

	Hit.Damage = Damage;
	Hit.Daze = Daze;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', 0.25)
		end},

		{0.25, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(6, 6, 6), function(Enemy)
				Ability:Hit(Caster, Enemy, Hit)
			end)
		end}
	})
end

return Ability
