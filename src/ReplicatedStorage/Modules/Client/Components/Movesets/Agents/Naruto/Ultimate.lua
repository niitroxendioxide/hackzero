--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Cutscenes = require(ReplicatedStorage.Modules.Client.Libraries.Cutscenes)
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Context)
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Cutscenes:Start("Naruto Ultimate", Caster)

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, "Naruto.Abilities.Ultimate.CastJutsu", {Active_Time = 0.5})
			Caster:SwitchState('Attacking', Attack_Time, true)
		end},
	})
end

return Ability
