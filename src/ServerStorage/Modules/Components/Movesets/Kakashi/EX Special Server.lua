--
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService('ServerStorage')

const Shared = ReplicatedStorage.Modules.Shared
const Classes = ServerStorage.Modules.Classes

const GrabService = require(ServerStorage.Modules.Services.Combat.GrabService)
const Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
const Types = require(Shared.Types.Abilities)
const AbilityClass = require(Classes.Combat.ServerAbility)

--
const Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.ServerAgent)
	Caster:Walk(0, 1)

	local GrabbedEnemy = Ability:Get(Caster, 'GrabbedEnemy')
	if GrabbedEnemy then
		GrabService:ForceStopGrab(GrabbedEnemy)
	end
end)

const function CastSosenko(Caster: Types.ServerAgent, Context: Types.SkillContext)
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Table.CopyDeep(Ability:FromData("Hit", nil, SkillLevel))

	local Attack_State_Time = Ability:FromData('Attack_State_Time');
	local First_Hit_Time = Ability:FromData('First_Run_Time')
	local Second_Hit_Time = Ability:FromData('Second_Run_Time')
	local Total_Run_Time = First_Hit_Time + Second_Hit_Time
	local Grabbed_Enemy = false

	local Hit_Count = Ability:FromData('Sosenko_Hit_Max')
	local Hit_Frequency = Ability:FromData('Sosenko_Hit_Frequency')

	const Hit_Counts = {}
	const Hit_Enemies = {}

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
		end},

		{0.4, function()
			Caster:Walk(Total_Run_Time, 1.05, true)
		end},

		{0.4, 0.4 + First_Hit_Time, function(SequenceTime)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -3), vector.create(6, 4, 6), function(Enemy)
				if not Grabbed_Enemy then
					Grabbed_Enemy = true;
					
					local RemainingTime = (Total_Run_Time + 0.4) - SequenceTime.__currentTime
					GrabService:GrabEnemy(Caster, Enemy, RemainingTime, CFrame.new(0, 0, -3.5))
					Ability:Save(Caster, 'GrabbedEnemy', Enemy)

					task.delay(RemainingTime, function()
						if Ability:Get(Caster, 'GrabbedEnemy') == Enemy then
							Ability:Save(Caster, 'GrabbedEnemy', nil)
						end
					end)
				end

				if Hit_Enemies[Enemy] or (Hit_Counts[Enemy] or 0) >= Hit_Count then
					return
				end

				Hit_Enemies[Enemy] = true;
				Hit_Counts[Enemy] = (Hit_Counts[Enemy] or 0) + 1;

				task.delay(Hit_Frequency, function()
					Hit_Enemies[Enemy] = nil
				end)

				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},

		{0.41 + First_Hit_Time, 0.41 + Total_Run_Time, function()
			if not Grabbed_Enemy then
				return
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -3), vector.create(6, 7, 6), function(Enemy)
				if Hit_Enemies[Enemy] or (Hit_Counts[Enemy] or 0) >= Hit_Count then
					return
				end

				Hit_Enemies[Enemy] = true;
				Hit_Counts[Enemy] = (Hit_Counts[Enemy] or 0) + 1;

				task.delay(Hit_Frequency, function()
					Hit_Enemies[Enemy] = nil
				end)

				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},

		{0.4 + First_Hit_Time, function(self)
			if Grabbed_Enemy then
				table.clear(Hit_Counts)

				return	
			end

			Caster:Walk(0)
			Caster:ImpulseForward(8, 0.75)
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, 0.3)
			self:Destroy()
		end}
	})
end

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	CastSosenko(Caster, Context)
end

return Ability
