--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 3})
end)

const function TryEnterLightningMode(Caster: Types.ServerAgent): boolean
	if Caster:HasTag('LightningMode') then
		return true
	end

	Ability:Save(Caster, 'SkillHeld', true)
	
	const Hold_Time = Ability:FromData('Lightning_Mode_Hold_Time')
	const HoldStart = os.clock();
	
	Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Hold_Time)

	while (Ability:Get(Caster, "SkillHeld") == true) do
		const Was_Held = (os.clock() - HoldStart) >= Hold_Time

		if Was_Held then
			Ability:Effect('Kakashi_LightningMode', Caster, 'Enter')

			return true
		end

		task.wait()
	end

	return false
end

function Ability:Play(Caster: Types.ClientAgent, _, State, Context)
	if State == 'Release' then
		Ability:Save(Caster, 'SkillHeld', false)
		
		return;
	else
		TryEnterLightningMode(Caster)
	end

	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.2)
	end

	const In_Lightning_Mode = Caster:HasTag('LightningMode')
	const Electric_Steps = Ability:FromData('Lightning_Mode_Steps')

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.M1.'..M1_Count, {
				Fade = .1,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},
	}, true)

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
				Ability:Hit(Caster, Target, {
					NoHitStop = true,
					EffectData = Is_Electric_Step and {
						HueShift = 175,
						Highlight = true,
						HighlightColor = Color3.fromRGB(117, 150, 244),
					} or nil,
				})
			end
		})
	end

	Sequence:Start()
end

return Ability
