--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()
	local Attack_Time = Ability:FromData("Attack_State_Time")

	local Range = Ability:FromData("Range")
	local CloneStunRange = Ability:FromData("Clone_Grab_Time")
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time, true)
		end},

		{0.3, function()

			for _, Enemy: Types.ServerEnemy in Enemies:GetAll() do
				local InRange = (Enemy:GetPivot().Position - Caster:GetPivot().Position).Magnitude <= Range;
				if InRange then
					Enemy:SwitchState("Frozen", CloneStunRange)

					Ability:Effect("Naruto_GrabClone", {Caster, Enemy:GetId()}, true)
				end

			end

		end}
	})
end

return Ability
