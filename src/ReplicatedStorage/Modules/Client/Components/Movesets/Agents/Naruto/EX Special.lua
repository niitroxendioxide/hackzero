--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

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

		{1.2, function()
			Track = Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.RunningRasengan", {Speed = 1.5, Fade = 0.15, Loop = true})
			Caster:ImpulseForward(75, 0.2)
			Caster:Walk(2, 1.15, true)

			if Caster.__Player_Assigned == Players.LocalPlayer then
				Camera:UseFov(2, 90, 0.25)
				Camera:UseZoom(2, 16)
			end
		end},

		{1.2, 3.2, function()
			if Caster.__Player_Assigned == Players.LocalPlayer then
				Caster:Look(Camera:HorizontalVector(), true, true)
			end
		end},

		{3.2, function()
			if not Track then
				return
			end

			Track:Stop()
		end}
	})
end

return Ability
