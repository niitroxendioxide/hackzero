--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Agents = require(ServerStorage.Modules.Libraries.Agents)
const Math = require(Shared.Utility.Math)
const Types = require(Shared.Types)
const AbilityTypes = require(Shared.Types.Abilities)
const AbilityClass = require(Classes.Combat.ServerAbility)
const Characters = require(Shared.Database.Characters)

--
local Ability = AbilityClass.new()

const function CanStunGrenade(Caster: AbilityTypes.ServerAgent)
	const Player = Caster.__Player_Assigned
	const RepId = Player:GetAttribute("ReplicationId");

	for _, Agent in Agents:GetAll(RepId) do
		const Data = Characters:GetCharacterData(Agent.Name, true)
		if Data.Role == "Stun" then
			return true
		end
	end
	
	return false
end

const function GetLandPosition(Caster: Types.GenericClass, Target: any?): Vector3
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

const function Shoot(Caster: Types.GenericClass, Land: Vector3, HitData)
	const Offset = Caster:GetPivot():PointToObjectSpace(Land)

	Ability:CreateHitbox(Caster, Offset, Ability:FromData("Grenade_Size"), function(Enemy)
		Ability:Hit(Caster, Enemy, HitData)
	end)
end

const function Throw(Caster: Types.GenericClass, Target: any?)
	const Start = Caster:GetPivot().Position
	const Land = GetLandPosition(Caster, Target)
	const FlightTime = Math:GetArc(Start, Land, Ability:FromData("Grenade_Speed"), Ability:FromData("Grenade_Lift"))
	const IsStunGrenade = CanStunGrenade(Caster)
	const HitData = if IsStunGrenade then Ability:FromData("Stun_Grenade", nil, Caster:GetSkillLevel(Ability.__Name))
	else Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))

	task.delay(FlightTime, Shoot, Caster, Land, HitData)
end

function Ability:Play(Caster: Types.GenericClass, _, State, Ctx): ()
	if State ~= 'Begin' then
		return
	end

	Ability:Begin(Caster, {
		{0, function()
			if Ctx.Target then
				Caster:LookAtTarget(Ctx.Target)
			end

			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end},

		{0.267, function()
			Throw(Caster, Ctx.Target)
		end},
	})
end

return Ability
