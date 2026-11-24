--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Math = require(Shared.Utility.Math)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)
const Characters = require(Client.Libraries.Characters)
const Database = require(Shared.Database.Characters)
const Animation = require(Client.Libraries.Animation)

--
const Ability = AbilityClass.new()

const function CanStunGrenade(Caster: Types.ClientAgent)
	const RepId = Caster.__Player_Assigned:GetAttribute("ReplicationId") :: number;
	const List = Characters:GetCharacters(RepId)

	for _, Agent : Types.ClientAgent in List do
		const Data = Database:GetCharacterData(Agent.Name, true)
		if Data.Role == 'Stun' then
			return true
		end
	end
	
	return false
end

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

const function Shoot(Caster: Types.ClientAgent, Land: Vector3, IsStun: boolean?)
	const Offset = Caster:GetPivot():PointToObjectSpace(Land)
	const Obj = Animation:GetAnim("Characters.Lelouch.Abilities.Assist.Blindness");

	Ability:CreateHitbox(Caster, Offset, Ability:FromData("Grenade_Size"), function(Enemy)
		if IsStun then
			const Track = Animation:Play(Enemy:GetModel(), Obj, 0, 1, 1.33);
			task.delay(1.55, function()
				Track:Stop(.3)
			end)
		end

		Ability:Hit(Caster, Enemy, {EffectData = {
			Highlight = true,
			HueShift = 30,
			HighlightColor = not IsStun and Color3.fromRGB(255, 154, 54) or Color3.fromRGB(255, 223, 154)
		}, NoCameraShake = true, NoHitStop = true})
	end)
end

const function Throw(Caster: Types.ClientAgent, Target: Types.ClientEnemy?)
	const Start = Caster:GetPivot().Position
	const Land = GetLandPosition(Caster, Target)
	const FlightTime, Height = Math:GetArc(Start, Land, Ability:FromData("Grenade_Speed"), Ability:FromData("Grenade_Lift"))
	const Stun = CanStunGrenade(Caster)

	Ability:Effect("Lelouch_Grenade", Start, Land, Height, FlightTime, Stun)

	task.delay(FlightTime, Shoot, Caster, Land, Stun)
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
