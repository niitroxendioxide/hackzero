--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Animation = require(Client.Libraries.Animation)
local Camera = require(Client.Libraries.Camera)
local Types = require(Shared.Types.Abilities)
local Statics = require(Shared.Database.Statics)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


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
	local Limit = 1
	local Time = 2;
	local HitCount = Ability:FromData("Hit_Count")

	local function ReleaseRasengan(Enemy: Types.ServerEnemy)
		if Released then
			return;
		end

		if Caster.__Player_Assigned == Players.LocalPlayer then
			Camera:UseFov(0.25, 70, 0.25)
			Camera:ResetZoom()
		end

		Released = true

		for GrabbedEnemy in HitList do
			task.spawn(function()
				for i = 1, HitCount do
					Ability:Hit(Caster, GrabbedEnemy, {EffectData = {HueShift = 50}})

					task.wait(1 / 8)
				end
			end)
		end

		if not Enemy then
			return
		end

		for i = 1, HitCount do
			Ability:Hit(Caster, Enemy, {EffectData = {HueShift = 50}})

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
				if Table:GetDictLength(HitList) > Limit then
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
					Ability:Hit(Caster, Enemy, {})
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

return Ability
