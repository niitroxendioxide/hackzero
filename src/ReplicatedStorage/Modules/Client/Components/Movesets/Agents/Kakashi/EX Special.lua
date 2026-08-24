--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
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

	local Total_Run_Time = First_Hit_Time + Second_Hit_Time

	local Track: AnimationTrack = nil;
	local Grabbed_Enemy = false

	local Hit_Enemies = {}
	local Hit_Counts = {}

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
					Grabbed_Enemy = true;

					if Track and Track.IsPlaying then
						Track:Stop(0.15)
					end

					Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.Special.DoubleRaikiriGrabRun', {Loop = true, Fade = 0.15})
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

		{0.41 + First_Hit_Time, 0.41 + Total_Run_Time, function()
			if not Grabbed_Enemy then
				return
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -3), vector.create(6, 4, 6), function(Enemy)
				if not Grabbed_Enemy then
					Grabbed_Enemy = true;
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

		{0.41 + Total_Run_Time, function()
			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

			Ability:Effect("Kakashi_Raikiri", Caster, 'Delete')
		end},
		
		{0.4 + First_Hit_Time, function(self)
			if Grabbed_Enemy then
				table.clear(Hit_Counts)

				return;
			end

			if Track and Track.IsPlaying then
				Track:Stop(0.15)
			end

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