--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local GrabService = require(ServerStorage.Modules.Services.Combat.GrabService)
local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Table.CopyDeep(Ability:FromData("Hit", nil, SkillLevel))
	local Attack_State_Time = Ability:FromData('Attack_State_Time');
	local Hit_Count = math.floor(Ability:FromData('Hit_Count', nil, SkillLevel + 1))
	local Hit_Frequency = Ability:FromData('Hit_Frequency')
	local Single_Hit = false;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
		end},

		{0.4, function()
			Caster:Walk(0.5, 1, true)
			
		end},

		{0.4, 0.9, function()
			if Single_Hit then
				return;
			end

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -2), vector.create(4, 4, 5), function(Enemy)
				if Single_Hit then
					return;
				end

				Caster:Walk(Hit_Count * Hit_Frequency, 1)
				Single_Hit = true;
				Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Hit_Count * Hit_Frequency + 0.1)

				GrabService:GrabEnemy(Caster, Enemy, Hit_Frequency * Hit_Count, CFrame.new(0, 0, -3.25))

				for i = 1, Hit_Count do
					if i == Hit_Count then
						HitData.Knockback = Ability:FromData('KnockbackData') 
					end

					Ability:Hit(Caster, Enemy, HitData)

					task.wait(Hit_Frequency)
				end
			end)
		end}
	})
end

return Ability
