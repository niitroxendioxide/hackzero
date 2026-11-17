--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Math = require(Shared.Utility.Math)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

const function GetLandPosition(Caster: Types.ClientAgent, Target: Types.ClientEnemy?): Vector3
	const Pivot = Caster:GetPivot()
	const Range = Ability:FromData("Range")

	if Target == nil then
		return (Pivot * CFrame.new(0, 0, -Ability:FromData("Throw_Distance"))).Position
	end

	const Offset = Pivot:PointToObjectSpace(Target:GetPivot().Position)
	if Offset.Magnitude > Range then
		return Pivot:PointToWorldSpace(Offset.Unit * Range)
	end

	return Target:GetPivot().Position
end

const function Shoot(Caster: Types.ClientAgent, Land: Vector3)
	const Offset = Caster:GetPivot():PointToObjectSpace(Land)

	Ability:CreateHitbox(Caster, Offset, Ability:FromData("Grenade_Size"), function(Enemy)
		Ability:Hit(Caster, Enemy, {EffectData = {}, NoCameraShake = true, NoHitStop = true})
	end)
end

const function Throw(Caster: Types.ClientAgent, Target: Types.ClientEnemy?)
	const Start = Caster:GetPivot().Position
	const Land = GetLandPosition(Caster, Target)
	const FlightTime, Height = Math:GetArc(Start, Land, Ability:FromData("Grenade_Speed"), Ability:FromData("Grenade_Lift"))

	Ability:Effect("Lelouch_Grenade", Start, Land, Height, FlightTime)

	task.delay(FlightTime, Shoot, Caster, Land)
end

function Ability:Play(Caster: Types.ClientAgent, _, _State, Context)
	const Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.Special.ThrowGrenade', {
				Fade = .1,
			})

			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.267, function()
			Throw(Caster, Context.Target)
		end},
	})
end

return Ability
