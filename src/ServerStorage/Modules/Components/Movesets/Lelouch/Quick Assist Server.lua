--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

const Math = require(Shared.Utility.Math)
local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
const Ability = AbilityClass.new()

const function GetCenter(Caster: Types.GenericClass, Target: any?): Vector3
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

const function GetGrenades(Start: Vector3, Center: Vector3): { {Land: Vector3, FlightTime: number} }
	const Count = Ability:FromData("Grenade_Count")
	const Spread = Ability:FromData("Grenade_Spread")
	const Facing = CFrame.lookAt(Start, vector.create(Center.X, Start.Y, Center.Z))
	const Distance = (Center - Start).Magnitude

	const BaseFlight = math.max(Distance / Ability:FromData("Grenade_Speed"), 1 / 60)

	const Grenades = {}
	for i = 0, Count - 1 do
		const Side = (Count > 1) and (i / (Count - 1)) * 2 - 1 or 0
		const Land = Center + Facing.RightVector * (Side * Spread) - Facing.LookVector * (math.abs(Side) * Spread * 0.35)

		table.insert(Grenades, {
			Land = Land,
			FlightTime = BaseFlight + i * Ability:FromData("Grenade_Stagger"),
		})
	end

	return Grenades
end

const function Explode(Caster: Types.GenericClass, Land: Vector3, HitData)
	const Offset = Caster:GetPivot():PointToObjectSpace(Land)

	Ability:CreateHitbox(Caster, Offset, Ability:FromData("Grenade_Size"), function(Enemy)
		Ability:Hit(Caster, Enemy, HitData)
	end)
end

const function Throw(Caster: Types.GenericClass, Target: any?)
	const HitData = Ability:FromData("Grenade_Hit", nil, Caster:GetSkillLevel(Ability.__Name))
	const Start = Caster:GetPivot().Position
	const Center = GetCenter(Caster, Target)

	for _, Grenade in GetGrenades(Start, Center) do
		task.delay(Grenade.FlightTime, Explode, Caster, Grenade.Land, HitData)
	end
end

function Ability:Play(Caster: Types.GenericClass, _, _State, Ctx): ()
	const Hit = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.Name))

	Ability:Begin(Caster, {
		{0, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end

			Caster:WalkBack(.3, 1.5)
			Caster:SwitchState('Attacking', Ability:FromData("Attack_State_Time"))
		end},

		{0.35, function()
			const At = Caster:GetPivot():ToObjectSpace(Ctx.Target:GetPivot()).Position

			Ability:CreateHitbox(Caster, At, vector.create(10, 4, 10), function(Target)
				Ability:Hit(Caster, Target, Hit)
			end)
		end},

		{0.55, function()
			Throw(Caster, Ctx.Target)
		end},
	})
end

return Ability
