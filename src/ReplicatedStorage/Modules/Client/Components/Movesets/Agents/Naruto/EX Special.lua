--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local World = require(ReplicatedStorage.Modules.Shared.World)
local Animation = require(Client.Libraries.Animation)
local Camera = require(Client.Libraries.Camera)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.ClientAgent, _, _, ctx)
	--
	local AttackTime = Ability:FromData('Attack_State_Time')
	
	local Track = nil;
	local hasHit = false;
	local Offset, Size = Ability:FromData("Hitbox_Offset"), Ability:FromData("Hitbox_Size")
	
	local HitList = {};
	local Released = false;
	local Limit = Ability:FromData("Limit");
	local Time = Ability:FromData("Length");
	local Frequency = 1 / 8
	local HitCount = Ability:FromData("Hit_Count")
	local Tracks = {}

	local function ReleaseRasengan(Enemy: Types.ServerEnemy)
		if Released then
			return;
		end


		if Caster.__Player_Assigned == Players.LocalPlayer then
			Camera:UseFov(0.25, 70, 0.25)
			Camera:ResetZoom()
		end

		Caster:SwitchState('Attacking', 0.45)
		Ability:PlayAnimation(Caster, 'Naruto.Abilities.Special.RasenganRelease', {
			Active_Time = 0.5
		})

		if hasHit then
			Ability:Effect("Naruto_Rasengan", Caster, "Release")
		end

		task.delay(0.13 / (Ability:FromData("Speed") * Ability:FromData("Animation_Speed") * World:GetSpeed()), function()
			Caster:ImpulseForward(-45, 0.2)
		end)

		for _, Track in Tracks do
			Track:Stop()
		end

		Released = true

		for GrabbedEnemy in HitList do
			Ability:Effect("Naruto_RasenganHit", GrabbedEnemy, HitCount, Frequency)

			task.spawn(function()
				for i = 1, HitCount do
					Ability:Hit(Caster, GrabbedEnemy, {EffectData = {HueShift = 170}, NoHitStop = true})

					if HitCount == i then
						Ability:Effect("GroundRocksTrail", GrabbedEnemy, 0.25, false)
					end

					task.wait(Frequency)
				end
			end)
		end

		if not Enemy then
			return
		end

		Ability:Effect("Naruto_RasenganHit", Enemy, HitCount, Frequency)
		for i = 1, HitCount do
			Ability:Hit(Caster, Enemy, {EffectData = {HueShift = 170}, NoHitStop = true})

			if HitCount == i then
				Ability:Effect("GroundRocksTrail", Enemy, 0.25, false)
			end

			task.wait(1 / 8)
		end
	end


	Ability:Begin(Caster, {
		{0, function(self: Types.Sequence)
			Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.RasenganUser", {})
			Caster:SwitchState('Attacking',  AttackTime)
		end},

		{0.075, function()
			Ability:Effect("Handsigns", Caster, 0.1)
		end},

		{0.25, function()
			local Object = Animation:GetAnim("Characters.Naruto.Abilities.Special.RasenganClone")
			Ability:Effect('Naruto_Clone', Caster, 1.12, CFrame.new(4.815, 0, 0.212), {Object = Object, Speed = 1, CFrameTween = {0.15, 'Quad'}, OriginOffset = CFrame.new(0, 0, 0)})
		end},

		{0.35, function()
			Ability:Effect("Naruto_Rasengan", Caster, 'Charge', Time)
		end},

		{1.2, function()
			Track = Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.RunningRasengan", {Speed = 1.5, Fade = 0.15, Loop = true})
			Caster:ImpulseForward(75, 0.2)
			Caster:Walk(Time, 1.15, true)

			Ability:Effect("Naruto_Rasengan", Caster, 'Running', Time)
		end},

		{1.2, 1.15 + Time, function()
			if Released then
				return
			end

			if Caster.__Player_Assigned == Players.LocalPlayer then
				local IsActive = Caster:IsActive()
				if not IsActive and not HitList[ctx.Target] then
					Caster:LookAtTarget(ctx.Target);
				elseif IsActive then
					Caster:Look(Camera:HorizontalVector(), true, true)
				end
			end

			Ability:CreateHitbox(Caster, Offset, Size, function(Enemy)
				if HitList[Enemy] then
					return
				end

				if Table:GetDictLength(HitList) >= Limit then
					ReleaseRasengan(Enemy)
					Caster:Walk(0.001, 1, true)
					if Track and Track.IsPlaying then
						Track:Stop()
					end

					return
				end

				---
				if not hasHit then
					hasHit = true

					if Track and Track.IsPlaying then
						Track:Stop(0.2)
						Track:Destroy()
					end

					Track = Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.RunningRasenganHit", {Speed = 1.5, Fade = 0.15, Loop = true})
				end

				if not HitList[Enemy] then
					HitList[Enemy] = true
					Ability:Hit(Caster, Enemy, {NoAnim = true, EffectData = {HueShift = 170, Highlight = true, HighlightColor = Color3.fromRGB(255, 189, 57)},})

					local Grab = Animation:GetAnim("Characters.Naruto.Abilities.Special.EnemyGrab")
					local AnimTrack = Animation:Play(Enemy:GetModel(), Grab, 0, 1, 1)
					table.insert(Tracks, AnimTrack)
				end
			end)
		end},

		{1.2 + Time, function()
			if not Track then
				return
			end

			ReleaseRasengan()
			Track:Stop()
		end}
	})
end

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeCancel, function(Caster: Types.ClientAgent)
	Caster:Walk(0.001, 1, true)
	Ability:Effect("Naruto_Rasengan", Caster, "Release")
end)

return Ability
