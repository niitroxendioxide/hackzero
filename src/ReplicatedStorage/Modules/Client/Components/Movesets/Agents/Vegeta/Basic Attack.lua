--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 5})
end)

const function HandleKiCharge(Caster: Types.ClientAgent)
	Ability:Save(Caster, "Charging", true)

	local Track = Ability:PlayAnimation(Caster, "Vegeta.Abilities.M1.Startup", {Active_Time = 0.45, Fade = .175})
	local HasCharged = false;
	const Clock = os.clock();
	Caster:SwitchState('Attacking', 1e12)

	local SwitchedOff = false;

	while Ability:Get(Caster, "Charging") == true do
		if SwitchedOff and Caster:IsActive() then
			break
		end

		if not HasCharged and (os.clock() - Clock) > 0.3 then
			Track:Stop(.125)
			Track = Ability:PlayAnimation(Caster, "Vegeta.Abilities.M1.Loop", {})
			Caster:AddTag('HoldingKiCharge', 1e12)
			Ability:Effect("Vegeta_KiCharge", Caster)
			HasCharged = true; 
		end

		if not Caster:IsActive() then
			SwitchedOff = true
		end

		task.wait()
	end

	
	Caster:SwitchState('Idle', 0)
	Track:Stop(.125)

	Caster:RemoveTag('HoldingKiCharge')

	return HasCharged
end

function Ability:Play(Caster: Types.Caster, _, State, Context)

	if State == 'Release' then
		Ability:Save(Caster, "Charging", false)

		return;
	else
		const Charged = HandleKiCharge(Caster)
		if Charged then return end;
	end

	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Caster, 'Template.Abilities.M1.'.. math.clamp(1 + M1_Count % 2, 1, 2) , {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{.18, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ClientEnemy)
				Ability:Hit(Caster, Target, {})
			end)
		end,},
	})

end

return Ability