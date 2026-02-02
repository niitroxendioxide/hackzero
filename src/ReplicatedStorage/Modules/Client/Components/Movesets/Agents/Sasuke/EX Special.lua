--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.Caster, _, _, ctx)
	--
	print(ctx)
	local AttackTime = Ability:FromData('Attack_State_Time')

	Ability:Begin(Caster, {
		{0, function(self: Types.Sequence)
			Ability:PlayAnimation(Caster, "Sasuke.Abilities.Special.KatonThread", {})
			Caster:SwitchState('Attacking',  AttackTime)
		end},
	})
end

return Ability
