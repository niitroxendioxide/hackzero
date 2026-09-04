--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(Client.Libraries.Animation)
local Camera = require(Client.Libraries.Camera)
local Replicator = require(Client.Libraries.Replicator)
local Effects = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')
	Caster:Walk(0, 1)

	local Sequence = Ability:Get<<Types.Sequence>>(Caster, "SuccessfulHitSequence")
	if Sequence then
		Sequence:Destroy()
		Ability:Save(Caster, "SuccessfulHitSequence", nil)
	end

	---
	local IsUsingRaiden = Ability:Get(Caster, 'using_raiden');
	if IsUsingRaiden then
		Ability:Effect("Kakashi_Raiden", Caster, 'Delete');
	end
end)


const function CastSosenko(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	local Attack_State_Time = Ability:FromData("Attack_State_Time")
	local First_Hit_Time = Ability:FromData('First_Run_Time')
	local Second_Hit_Time = Ability:FromData('Second_Run_Time')
	local Hit_Count = Ability:FromData('Sosenko_Hit_Max')
	local Hit_Frequency = Ability:FromData('Sosenko_Hit_Frequency')
	const DashHitboxSize = Ability:FromData('Sosenko_Dash_Hitbox_Size')

	local Total_Run_Time = First_Hit_Time + Second_Hit_Time

	local Track: AnimationTrack = nil;
	local Grabbed_Enemy = false

	local Hit_Enemies = {}
	local Hit_Counts = {}
	local Tracks = {}
	
	local Effect_Data = {
		NoHitStop = true,
		NoCameraShake = true,
		EffectData = {
			HueShift = 190,
			Highlight = true,
			HighlightColor = Color3.fromRGB(170, 251, 255),
			Weld = true,
		}
	}

	local SosenkoHitTarget: Types.ClientEnemy = nil
	local SuccessfulHitSequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, 1.75);
		end},

		{0, 0.6 - Replicator:GetPing(), function()
			if Caster.__Player_Assigned == Players.LocalPlayer then
				Caster:Look(Camera:HorizontalVector(), false, true)
			end
		end},

		{0.05, function()
			local Grab = Animation:GetAnim("Characters.Kakashi.Abilities.Special.DoubleRaikiriVictim")
			local AnimTrack = Animation:Play(SosenkoHitTarget:GetModel(), Grab, 0, 1, 1)

			table.insert(Tracks, AnimTrack)
			Ability:Effect("Kakashi_Raikiri", Caster, 'PauseAndDelete', 1)
		end},

		{0.55, function()
			Ability:Effect('Kakashi_Raikiri', Caster, 'Resume')
		end},

		{0.7, function()
			Ability:Effect("Throw", SosenkoHitTarget:GetPivot() * CFrame.Angles(0, math.pi, 0))

			Ability:Effect('Kakashi_RaikiriDash', Caster, 'Charge')
		end},
		
		{0.95, function()
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DoubleRaikiriFollowup', {Fade = 0.15})
		end},

		{1.35, function()
			Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')

			---
			local Direction = CFrame.lookAt(Caster:GetPivot().Position, SosenkoHitTarget:GetPivot().Position).LookVector
			local Pos = Caster:GetPivot().Position
			local Cast = Effects:CastMapRaycast(Pos, Direction * 45);
			local EndCFrame = CFrame.lookAlong(Pos, Direction) * CFrame.new(0, 0, -45)
			if Cast then
				EndCFrame = CFrame.lookAlong(Cast.Position - Cast.Normal * 2, Direction)
			end

			Ability:Save(Caster, 'OriginCFrame', CFrame.lookAlong(Pos, Direction))
			Ability:Save(Caster, 'EndingCFrame', EndCFrame)
			table.clear(Hit_Enemies)
		end},

		{1.4, function()
			local CFBase = Ability:Get(Caster, "OriginCFrame")
			Ability:Effect('Kakashi_RaikiriDash', Caster, '_', CFBase)

			local End = Ability:Get(Caster, 'EndingCFrame')

			Caster:PivotTo(End)
		end},

		{1.4, 1.6, function(Sequence)
			local Origin = Ability:Get(Caster, 'OriginCFrame')
			local Offset = Caster:GetPivot():ToObjectSpace(Origin * CFrame.new(0, 0, -DashHitboxSize.z/2)).Position
			Ability:CreateHitbox(Caster, Offset, DashHitboxSize, function(NewEnemy)
				if Hit_Enemies[NewEnemy] then
					return
				end

				Hit_Enemies[NewEnemy] = true
				task.delay(Hit_Frequency, function()
					Hit_Enemies[NewEnemy] = nil
				end)

				Ability:Hit(Caster, NewEnemy, Effect_Data)
			end)
		end},
	}, true)

	SuccessfulHitSequence:After(function(self: Types.Sequence)
		Ability:Save(Caster, 'LastCast', os.clock())
	end)
	Ability:Save(Caster, 'SuccessfulHitSequence', SuccessfulHitSequence)

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)

			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DoubleRaikiriSetup', {Loop = true})
		end,},

		{0.22, function()
			Ability:Effect("Kakashi_Raikiri", Caster, 'Charge', true)
		end},

		{0.4, function()
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DoubleRaikiriRun', {Loop = true})
			Caster:Walk(Total_Run_Time, 1.05, true)
		end},

		{0.4, 0.4 + Total_Run_Time, function()
			if Grabbed_Enemy or (Context.Target == nil) then
				local IsActive = Caster:IsActive()

				if Caster.__Player_Assigned == Players.LocalPlayer and IsActive then
					Caster:Look(Camera:HorizontalVector(), true, true)
				end

				return
			end

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{0.4, 0.4 + First_Hit_Time, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -3), vector.create(6, 4, 6), function(Enemy)
				if not Grabbed_Enemy then
					if Enemy:IsAirborne() then
						return;
					end

					Grabbed_Enemy = true;

					if Track and Track.IsPlaying then
						Track:Stop(0.15)
					end

					Caster:Walk(0.5, 1.75)

					Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DoubleRaikiriSlamThrow', {Fade = 0.05})
					SosenkoHitTarget = Enemy
					SuccessfulHitSequence:Start()
				end

				if Hit_Enemies[Enemy] or (Hit_Counts[Enemy] or 0) >= Hit_Count then
					return
				end

				Hit_Enemies[Enemy] = true;
				Hit_Counts[Enemy] = (Hit_Counts[Enemy] or 0) + 1;

				task.delay(Hit_Frequency, function()
					Hit_Enemies[Enemy] = nil
				end)

				Ability:Hit(Caster, Enemy, Effect_Data)
			end)
		end},
		
		--- Total end
		{0.4 + First_Hit_Time, function(self)
			if Grabbed_Enemy then
				table.clear(Hit_Counts)

				return;
			end

			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

			Caster:Walk(0)
			Caster:ImpulseForward(8, 0.75)
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, 0.3)
			Ability:PlayAnimation(Caster, "Kakashi.Abilities.Special.RaikiriRunStop", {Speed = 1, Fade = 0})

			Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')

			self:Destroy()
		end,},
	}):After(function(self: Types.Sequence)
		Ability:Save(Caster, 'LastCast', os.clock())
	end)
end

const function Raiden(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Run_Time = Ability:FromData('Raiden_Run_Time')
	const Run_Power = Ability:FromData('Raiden_Run_Power')
	const Start_Time = Ability:FromData('Raiden_Startup_Time')
	const Hit_Frequency = Ability:FromData('Raiden_Hit_Frequency')
	const Allow_Full_Control = Ability:FromData('Raiden_Full_Control')
	
	const Skill_Usage_Time = Start_Time + Run_Time + 0.3;
	const Effect_Data = {
		NoCameraShake = false,
		NoHitStop = true,
		EffectData = {
			HueShift = 170,
			Highlight = true,
			HighlightColor = Color3.fromRGB(117, 150, 244),
		}
	}

	const Hit = {}
	const Hit_List = {}
	local Track : AnimationTrack = nil;
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.Raiden.FlipL', {})
			Ability:Save(Caster, 'using_raiden', true);
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Skill_Usage_Time);

			Ability:Effect("Kakashi_Raiden", Caster, 'Create', Start_Time);

			Caster:SetEnemyCollisionState(false, 5);
			Caster:Walk(0.35, -1.25)

			if Caster:IsLocalPlayerOwner() then
				Camera:DisableOffset()
			end
		end},

		{Start_Time, function()
			Track:Stop(0.15)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.Raiden.Left', {
				Loop = true,
			})
			Caster:Walk(Run_Time, Run_Power, true);
		end},

		{Start_Time, Start_Time + Run_Time, function()
			if (Allow_Full_Control == true) and (Caster:IsLocalPlayerOwner()) then
				Caster:Look(Camera:HorizontalVector(), true, true);
			end

			Ability:CreateHitbox(Caster, vector.zero, vector.create(21, 4, 6), function(Target)
				if (Hit_List[Target]) then return end;
				Hit_List[Target] = true;

				task.delay(Hit_Frequency, function()
					Hit_List[Target] = false;
				end)

				if not Hit[Target] then
					Ability:Hit(Caster, Target, {
						Track = 'Characters.Kakashi.Abilities.Special.Raiden.Hit',
						NoCameraShake = Effect_Data.NoCameraShake,
						NoHitStop = Effect_Data.NoHitStop,
						EffectData = Effect_Data.EffectData,
					})
				else
					Ability:Hit(Caster, Target, Effect_Data)
				end
			end)
		end},

		{Start_Time + Run_Time, function()
			Track:Stop(0);
		end}
	}, true)

	Sequence:After(function(self: Types.Sequence)
		Camera:EnableOffset()
		Caster:SetEnemyCollisionState(true, 5);
		Ability:Save(Caster, 'using_raiden', false);
		Ability:Effect("Kakashi_Raiden", Caster, 'Delete');
	end)

	Sequence:Start()
end

--[[
	ROUGH DRAFT - Lightning Mode replaces Raiden with 'Raikiri: Denko Rensen': no clone and no
	lightning blade, Kakashi just cuts through the target repeatedly while moving left and right.
	The zig-zag is sold by the animation and the dash VFX. Client half is feel only.
]]
const function DenkoRensen(Caster: Types.ClientAgent, Context: Types.ClientSkillContext)
	const Startup_Time = Ability:FromData('Denko_Rensen_Startup_Time')
	const Dash_Count = Ability:FromData('Denko_Rensen_Dash_Count')
	const Dash_Time = Ability:FromData('Denko_Rensen_Dash_Time')
	const Dash_Power = Ability:FromData('Denko_Rensen_Dash_Power')
	const Hitbox_Size = Ability:FromData('Denko_Rensen_Hitbox_Size')

	const Total_Time = Dash_Count * Dash_Time
	const Skill_Usage_Time = Startup_Time + Total_Time + 0.3;
	local LastHit = 0;
	local Track: AnimationTrack = nil;

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Skill_Usage_Time)
			Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DenkoRensenBegin', {Fade = 0.1})
			Ability:Effect('Kakashi_Raikiri', Caster, 'Charge', true)

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

			Ability:Effect('Kakashi_RaikiriDash', Caster, '_', Caster:GetPivot())

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), Hitbox_Size, function(Enemy)
				Ability:Hit(Caster, Enemy, {
					NoHitStop = true,
					EffectData = {
						HueShift = 175,
						Highlight = true,
						HighlightColor = Color3.fromRGB(117, 150, 244),
					},
				})
			end)
		end},
	}, true)

	Sequence:After(function(_self: Types.Sequence)
		if Track and Track.IsPlaying then
			Track:Stop(0.15)
		end

		Ability:Effect('Kakashi_Raikiri', Caster, 'Delete')
	end)

	Sequence:Start()
end

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Caster)
	local LastCast = Ability:Get(Caster, 'LastCast') or 0

	if (os.clock() - LastCast < 5) then
		Ability:PushToContextBuffer(true)
		Ability:Save(Caster, 'next_use_raiden', true)
	end
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	local IsRaiden = Ability:Get(Caster, 'next_use_raiden') == true
	Ability:Save(Caster, 'LastCast', os.clock())

	if IsRaiden then
		Ability:Save(Caster, 'next_use_raiden', false)

		-- In Lightning Mode the follow-up becomes Denko Rensen instead of Raiden (moveset.md).
		if Caster:HasTag('LightningMode') then
			DenkoRensen(Caster, Context)
		else
			Raiden(Caster, Context)
		end
	else
		CastSosenko(Caster, Context)
	end
end

return Ability