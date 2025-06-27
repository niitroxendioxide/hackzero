---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local MovesetClass = require(Shared.Classes.Moveset)
local CharacterDatabase = require(Shared.Database.Characters)

local TemplateMoveset = MovesetClass.new(script.Name)
local Data = CharacterDatabase:GetMovesetData(script.Name)

TemplateMoveset:SetAbilityInformation(Data)

for _, Ability in script:GetChildren() do
	local Success, Required = pcall(require, Ability)

	if Success then
		local Ability_Name = Ability.Name:gsub(' Server', '')
		
		Required:SetData(TemplateMoveset:GetInfoForSkill(Ability_Name))
		
		TemplateMoveset:Assign(Ability_Name, Required)
	end
end

return TemplateMoveset