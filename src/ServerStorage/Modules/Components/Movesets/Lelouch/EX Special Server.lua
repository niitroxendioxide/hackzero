--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Abilities = require(ReplicatedStorage.Modules.Shared.Types.Abilities)
local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

const LelouchGameplayController = require("./LelouchGameplayController")

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, State, Ctx): ()
	const Hitbox_Size = Ability:FromData("Geass_Area")
	const Yield_Command = Ability:FromData("Yield_Command")
	const Attack_State_Time = Ability:FromData('Attack_State_Time');

	Ability:Begin(Caster, {
		{0, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.35, function()
			const Center = Ctx.Target:GetPivot()
			const Offset = (Caster:GetPivot():ToObjectSpace(Center)).Position;
			const StrategyElement = LelouchGameplayController:GetStrategyElement(Caster);

			Ability:CreateHitbox(Caster, Offset, Hitbox_Size, function(Enemy: Abilities.ServerEnemy)
				const EnemyHasCommand = LelouchGameplayController:HasCommand(Caster, Enemy)
				if StrategyElement ~= nil then
					Enemy:AddEffect({
						Type = StrategyElement.."_Affliction_Resistance",
						Tag = 'CommandWeakness',
						Value = -0.1,
					})

					if EnemyHasCommand and Enemy:GetAffliction(StrategyElement) >= 50 then
						Enemy:TakeAffliction(StrategyElement, 50)
						Ability:Hit(Caster, Enemy, {
							Damage = 100,
							Affliction = StrategyElement,
							Forced_Affliction = true,
							Daze = 50,
							Affliction_Buildup = 100,
							Stun = 0.5,
						})
					end
				end
				
				LelouchGameplayController:ApplyCommand(Caster, Enemy, Yield_Command)
			end)
		end},

		{0.45, function()
			LelouchGameplayController:SummonKnight(Caster)
			LelouchGameplayController:SummonKnight(Caster)
		end},

		{0.35, 0.55, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end
		end},
	})
end

return Ability
