---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local MovesetClass = require(Shared.Classes.Moveset)
local CharacterDatabase = require(Shared.Database.Enemies)

local TemplateMoveset = MovesetClass.new(script.Name)

TemplateMoveset:SetAbilityInformation(CharacterDatabase:GetMovesetData(script.Name))

for _, Ability in script:GetChildren() do
	local Success, Required = pcall(require, Ability)

	if Success then
		if typeof(Required.SetData) == 'function' then
			Required:SetData(TemplateMoveset:GetInfoForSkill(Ability.Name))
		end
		
		TemplateMoveset:Assign(Ability.Name, Required)
	end
end

return TemplateMoveset