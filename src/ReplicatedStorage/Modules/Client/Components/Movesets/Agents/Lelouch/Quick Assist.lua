--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
const Math = require(Shared.Utility.Math)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
const Ability = AbilityClass.new()

const function GetCenter(Caster: Types.ClientAgent, Target: Types.ClientEnemy?): Vector3
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

const function GetGrenades(Start: Vector3, Center: Vector3): { {Land: Vector3, Height: number, FlightTime: number} }
	const Count = Ability:FromData("Grenade_Count")
	const Spread = Ability:FromData("Grenade_Spread")
	const Facing = CFrame.lookAt(Start, vector.create(Center.X, Start.Y, Center.Z))
	const Distance = (Center - Start).Magnitude

	const BaseFlight = math.max(Distance / Ability:FromData("Grenade_Speed"), 1 / 60)
	const BaseHeight = math.max(Distance * Ability:FromData("Grenade_Lift"), Ability:FromData("Grenade_Min_Height"))

	const Grenades = {}
	for i = 0, Count - 1 do
		const Side = (Count > 1) and (i / (Count - 1)) * 2 - 1 or 0
		const Land = Center + Facing.RightVector * (Side * Spread) - Facing.LookVector * (math.abs(Side) * Spread * 0.35)

		table.insert(Grenades, {
			Land = Land,
			Height = BaseHeight * (1 + i * Ability:FromData("Grenade_Lift_Step")),
			FlightTime = BaseFlight + i * Ability:FromData("Grenade_Stagger"),
		})
	end

	return Grenades
end

const function Explode(Caster: Types.ClientAgent, Land: Vector3)
	const Offset = Caster:GetPivot():PointToObjectSpace(Land)

	Ability:CreateHitbox(Caster, Offset, Ability:FromData("Grenade_Size"), function(Enemy)
		Ability:Hit(Caster, Enemy, {EffectData = {}, NoCameraShake = true, NoHitStop = true})
	end)
end

const function Throw(Caster: Types.ClientAgent, Target: Types.ClientEnemy?)
	const Start = Caster:GetPivot().Position
	const Center = GetCenter(Caster, Target)

	for _, Grenade in GetGrenades(Start, Center) do
		Ability:Effect("Lelouch_Grenade", Start, Grenade.Land, Grenade.Height, Grenade.FlightTime)
		task.delay(Grenade.FlightTime, Explode, Caster, Grenade.Land)
	end
end

function Ability:Play(Caster: Types.ClientAgent, _, _State, Context)
	const Attack_State_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.Assist.AssistAttack', {
				Fade = .1,
			})

			Caster:WalkBack(.3, 1.5)
			Caster:SwitchState('Attacking', Attack_State_Time)
		end},

		{0.35, function()
			const At = Caster:GetPivot():ToObjectSpace(Context.Target:GetPivot()).Position
			const Obj = Animation:GetAnim("Characters.Lelouch.Abilities.Assist.Blindness");

			Ability:CreateHitbox(Caster, At, vector.create(10, 4, 10), function(Target)
				const Track = Animation:Play(Target:GetModel(), Obj);
				task.delay(3, function()
					Track:Stop()
				end)

				Ability:Effect("Lelouch_GeassAffect", Target:GetId(), 2)
			end)
		end},

		{0.55, function()
			Throw(Caster, Context.Target)
		end},
	})
end

return Ability
