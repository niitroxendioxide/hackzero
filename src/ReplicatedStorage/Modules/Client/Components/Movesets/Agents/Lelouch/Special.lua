--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local CharacterDatabase = require(Shared.Database.Characters)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

const GEASS_COLOR = Color3.fromRGB(171, 97, 255)
const HIT_EFFECT_DATA = {
	Highlight = true,
	HighlightColor = GEASS_COLOR,
}

const GrenadeData = CharacterDatabase:GetMovesetData('Lelouch').Passive.Grenade

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	const Attack_State_Time = Ability:FromData('Attack_State_Time')
	const Throw_Time = Ability:FromData('Throw_Time')
	const Throw_Distance = Ability:FromData('Throw_Distance')
	const Geass_Time = Ability:FromData('Geass_Time')

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Attack_State_Time)
			Ability:PlayAnimation(Caster, 'Lelouch.Abilities.M1.Shoot', {Fade = 0.1})

			if Context.Target then
				Caster:LookAtTarget(Context.Target)
			end
		end},

		{Throw_Time, function()
			const At = if Context.Target then Context.Target:GetPivot() else Caster:GetPivot() * CFrame.new(0, 0, -Throw_Distance)
			const Offset = Caster:GetPivot():PointToObjectSpace(At.Position)

			Ability:CreateHitbox(Caster, Offset, GrenadeData.Size, function(Enemy)
				Ability:Hit(Caster, Enemy, {EffectData = HIT_EFFECT_DATA})
			end)
		end},

		{Geass_Time, function()
			Ability:Effect('Glow', Caster, {Color = GEASS_COLOR})
		end},
	})
end

return Ability
