--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local LelouchGameplayController = require("./LelouchGameplayController")
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent, _, _State, Context)
	const Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.267, function()
			const Random = math.random(1, 2) == 1 and 1 or -1

			Ability:CreateHitbox(Caster, vector.create(0, 0, -11), vector.create(16, 5, 22), function(Target)
				Ability:Stun(Target, 2)
			end)
			
			LelouchGameplayController:SummonKnight(Caster, Caster:GetPivot() * CFrame.new(8 * Random, 0, 0))
		end},
	})
end

return Ability
