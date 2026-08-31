--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Replicator = require(ReplicatedStorage.Modules.Client.Libraries.Replicator)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')
	Caster:Walk(0, 1)
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

			Ability:Save(Caster, 'OriginCFrame', Caster:GetPivot())
			Ability:Save(Caster, 'EndingCFrame', EndCFrame)
			table.clear(Hit_Enemies)
		end},

		{1.4, function()
			Ability:Effect('Kakashi_RaikiriDash', Caster)
		end},

		{1.38, 1.5, function(Sequence)
			local Origin = Ability:Get(Caster, 'OriginCFrame')
			local End = Ability:Get(Caster, 'EndingCFrame')

			local Progress = math.min((Sequence.__currentTime - 1.38) / 0.1, 1)
			local Alpha = TweenService:GetValue(Progress, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

			Caster:PivotTo(Origin:Lerp(End, Alpha))

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
	})
end

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	CastSosenko(Caster, Context)
end

return Ability