--
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService('ServerStorage')

const Shared = ReplicatedStorage.Modules.Shared
const Classes = ServerStorage.Modules.Classes

const GrabService = require(ServerStorage.Modules.Services.Combat.GrabService)
const Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
const Types = require(Shared.Types.Abilities)
const AbilityClass = require(Classes.Combat.ServerAbility)
const KakashiController = require(script.Parent.KakashiGameplayController)

--
const Ability = AbilityClass.new()

Ability:OnCancel(function(Caster: Types.ServerAgent)
	Caster:Walk(0, 1)

	local GrabbedEnemy = Ability:Get(Caster, 'GrabbedEnemy')
	if GrabbedEnemy then
		GrabService:ForceStopGrab(GrabbedEnemy)
	end

	local Sequence = Ability:Get<<Types.Sequence>>(Caster, "SuccessfulHitSequence")
	if Sequence then
		Sequence:Destroy()
		Ability:Save(Caster, "SuccessfulHitSequence", nil)
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
	const Throw_Hit = Ability:FromData('Throw_Hit', nil, SkillLevel)
	const SosenkoDashHit = Ability:FromData('Sosenko_Dash_Hit', nil, SkillLevel)

	const Hit_Counts = {}
	const Hit_Enemies = {}

	local Off = nil
	local Single_Hit = false
	local SosenkoHitTarget = nil
	local DashHitboxSize = Ability:FromData('Sosenko_Dash_Hitbox_Size')
	local SosenkoSuccessfulHit = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, 1);
		end},

		{0.6, function()
			if Ability:Get(Caster, 'GrabbedEnemy') == SosenkoHitTarget then
				Ability:Save(Caster, 'GrabbedEnemy', nil)
				GrabService:ForceStopGrab(SosenkoHitTarget)
			end

			Ability:Hit(Caster, SosenkoHitTarget, Throw_Hit)
		end},

		{1.35, function()
			local AttackOffset = CFrame.lookAt(Caster:GetPivot().Position, SosenkoHitTarget:GetPivot().Position) * CFrame.new(0, 0, -DashHitboxSize.z/2)
			Off = AttackOffset

			--[[local LookAtCFrame = CFrame.lookAt(Caster:GetPivot().Position, SosenkoHitTarget:GetPivot().Position);
			Caster:PivotTo(LookAtCFrame);]]

			table.clear(Hit_Enemies)
		end},

		{1.4, 1.6, function()
			local LocalOffset = (Caster:GetPivot():ToObjectSpace(Off)).Position
			Ability:CreateHitbox(Caster, LocalOffset, DashHitboxSize, function(NewTarget)
				if Hit_Enemies[NewTarget] then
					return
				end

				Hit_Enemies[NewTarget] = true;
				task.delay(Hit_Frequency, function()
					Hit_Enemies[NewTarget] = nil
				end)

				if not Single_Hit then
					Single_Hit = true
					KakashiController:AddCharge(Caster, 1)
				end

				Ability:Hit(Caster, NewTarget, SosenkoDashHit)
			end)
		end}
	}, true)

	Ability:Save(Caster, "SuccessfulHitSequence", SosenkoSuccessfulHit);

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
					local CouldGrab = GrabService:GrabEnemy(Caster, Enemy, 1, CFrame.new(0, 0, -5.6))
					if not CouldGrab then
						return;
					end

					Grabbed_Enemy = true;

					Caster:Walk(0.5, 1.75)
					Ability:Save(Caster, 'GrabbedEnemy', Enemy)
					SosenkoHitTarget = Enemy;
					SosenkoSuccessfulHit:Start()
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

const function Raiden(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const Run_Time = Ability:FromData('Raiden_Run_Time')
	const Run_Power = Ability:FromData('Raiden_Run_Power')
	const Start_Time = Ability:FromData('Raiden_Startup_Time')
	const Hit_Frequency = Ability:FromData('Raiden_Hit_Frequency')
	const Raiden_Hit = Ability:FromData('Raiden_Hit', nil, Caster:GetSkillLevel(Ability.Name))
	const Raiden_Knockback = table.clone(Ability:FromData("Raiden_Knockback"))
	const Paralyze_Time = Ability:FromData('Raiden_Paralyze_Time')

	const Skill_Usage_Time = Start_Time + Run_Time + 0.3;
	const Hit_List = {};
	const Hit = {}
	local Single_Hit = false;
	
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Skill_Usage_Time)
			Caster:Walk(0.35, -1.25)
		end},

		{Start_Time, function()
			Caster:Walk(Run_Time, Run_Power, true);
		end},

		{Start_Time, Start_Time + Run_Time, function()
			Ability:CreateHitbox(Caster, vector.zero, vector.create(21, 4, 6), function(Target)
				if (Hit_List[Target]) then return end;
				Hit_List[Target] = true;

				task.delay(Hit_Frequency, function()
					Hit_List[Target] = false;
				end)

				if not Single_Hit then
					Single_Hit = true
					KakashiController:AddCharge(Caster, 1)
				end

				local Cloned_Hit_Data = table.clone(Raiden_Hit)
				if (Hit[Target] == nil or os.clock() - Hit[Target] > Hit_Frequency*2) then
					Hit[Target] = os.clock();

					Raiden_Knockback[1] = Caster:GetPivot().LookVector
					Cloned_Hit_Data.Knockback = Raiden_Knockback

					Ability:Hit(Caster, Target, Cloned_Hit_Data)
				else
					Ability:Hit(Caster, Target, Cloned_Hit_Data)
				end

				KakashiController:Paralyze(Target, Paralyze_Time, Caster)
				
			end)
		end},

		{Start_Time + Run_Time, function()
		
		end}
	}, true);

	Sequence:After(function(self: Types.Sequence)
		Ability:Save(Caster, 'using_raiden', false);
	end)

	Sequence:Start()
end

const function DenkoRensen(Caster: Types.ServerAgent, Context: Types.SkillContext)
	const SkillLevel = Caster:GetSkillLevel(Ability.Name)
	const HitData = Table.CopyDeep(Ability:FromData('Denko_Rensen_Hit', nil, SkillLevel))

	const Startup_Time = Ability:FromData('Denko_Rensen_Startup_Time')
	const Dash_Count = Ability:FromData('Denko_Rensen_Dash_Count')
	const Dash_Time = Ability:FromData('Denko_Rensen_Dash_Time')
	const Dash_Power = Ability:FromData('Denko_Rensen_Dash_Power')
	const Hitbox_Size = Ability:FromData('Denko_Rensen_Hitbox_Size')

	const Total_Time = Dash_Count * Dash_Time
	const Skill_Usage_Time = Startup_Time + Total_Time + 0.3;
	local LastHit = 0;

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Skill_Usage_Time)

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Startup_Time, function()
			Caster:Walk(Total_Time, Dash_Power, true)
		end},

		{Startup_Time, Startup_Time + Total_Time, function()
			if (os.clock() - LastHit) < Dash_Time then
				return
			end

			LastHit = os.clock()

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end},
	}, true);

	Sequence:After(function(_self: Types.Sequence)
		Ability:Save(Caster, 'using_raiden', false);
	end)

	Sequence:Start()
end

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()
	const IsRaiden = Context.Buffer[1] == true;
	if IsRaiden then
		Ability:Save(Caster, 'next_use_raiden', false)

		-- In Lightning Mode the follow-up becomes Denko Rensen instead of Raiden (moveset.md).
		if KakashiController:IsLightningMode(Caster) then
			DenkoRensen(Caster, Context)
		else
			Raiden(Caster, Context)
		end
	else
		CastSosenko(Caster, Context)
	end
end

return Ability
