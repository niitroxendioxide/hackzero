--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local SasukeGameplayController = require("./SasukeGameplayController")

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster): ()
	---

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Ability:FromData("Attack_State_Time"))
		end},

		{0.25, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -7), vector.create(13, 8, 13), function(Enemy)  
				--- Join to sasuke somehow?
				SasukeGameplayController:ConnectThread(Enemy)
			end)
		end}
	})
end

return Ability
