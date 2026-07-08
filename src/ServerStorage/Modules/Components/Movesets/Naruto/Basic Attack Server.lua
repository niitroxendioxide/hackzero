--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()
	local M1_Count = (Context.M1_Count :: number)
	if (not M1_Count) then
		return
	end

	Ability:Begin(Caster, {
		{0, function()

		end},

		{0.2, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -5), vector.create(9, 9, 10), function(Enemy)  
				Ability:Hit(Caster, Enemy, Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name)))
			end)
		end}
	})
end

return Ability
