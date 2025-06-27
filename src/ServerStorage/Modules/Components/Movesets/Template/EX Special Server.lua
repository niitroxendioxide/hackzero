--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, Skill_Name: string, State: string, ...)
	--
	print("EX Special Template!")
	--local SkillLevel = Caster:GetSkillLevel('Special')

end

return Ability
