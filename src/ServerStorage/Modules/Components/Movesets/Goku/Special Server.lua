--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, ...)
	--
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

		{.2, function()
			Caster:Walk(.133)
		end,},

		{.35, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ServerEnemyClass)
				-- do stuff here :3
			end)
		end,},
	})
end

return Ability
