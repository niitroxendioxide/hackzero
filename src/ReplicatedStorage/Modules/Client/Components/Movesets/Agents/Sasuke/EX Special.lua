--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Statics = require(Shared.Database.Statics)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.Caster, _, _, ctx)
	--
	local AttackTime = Ability:FromData('Attack_State_Time')
	local IsThreadVariant = Caster:HasTag(Statics.Agent_Tags.Sasuke.Has_Enemies_Connected)
	
	Ability:Begin(Caster, {
		{0, function(self: Types.Sequence)
			Ability:PlayAnimation(Caster, "Sasuke.Abilities.Special.KatonThread", {})
			Caster:SwitchState('Attacking',  AttackTime)
		end},

		{0.25, function()
			if not IsThreadVariant then
				Ability:Effect("Sasuke_Fireball", Caster)
			end
		end}
	})
end

return Ability
