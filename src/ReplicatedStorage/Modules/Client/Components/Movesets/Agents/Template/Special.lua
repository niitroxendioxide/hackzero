--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, "Goku.Abilities.Special.Default", {Fade = .1, Active_Time = Attack_Time})

			Effects:Play("Glow", Caster)
		end},

		{.2, function()
			Caster:Walk(Ability:FromData('Walk_Time'))
		end},
	})

end

return Ability
