--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local EnemyData = {
	__Saved = {} :: {Types.CharacterData},
	__Ids = {},
}

function EnemyData:Init()
	for _, Module in script:GetChildren() do
		local Success, Character = pcall(require, Module)

		if Success then
			EnemyData.__Saved[Module.Name] = table.freeze(Character)
			
			table.insert(EnemyData.__Ids, Module.Name)
		else
			warn('Error on character data for:', Module.Name)
		end
	end
	
	table.sort(EnemyData.__Ids, function(a, b)
		return a < b
	end)
	
	table.freeze(EnemyData.__Ids)
end

function EnemyData:GetStats(Character: string): Types.CharacterStats
	local AccessedData = EnemyData:GetEnemyData(Character)
	
	return AccessedData.Stats
end

function EnemyData:GetAbilities(Character: string)
	local Data = EnemyData:GetEnemyData(Character)
	local Total = {}
	
	for Skill in Data.Moveset_Data do
		table.insert(Total, Skill)
	end
	
	return Total
end

function EnemyData:GetMovesetData(Enemy: string): Types.CharacterStats
	local AccessedData = EnemyData:GetEnemyData(Enemy)

	return AccessedData.Moveset_Data
end

function EnemyData:GetStatsAtLevel(Character: string, Level: number)
	local CharacterData = EnemyData:GetEnemyData(Character)
	
	local Converted = {}
	
	for Key, Value in CharacterData.Stats do
		local PerLevel = CharacterData.Level_Stats
		
		if PerLevel[Key] then
			Converted[Key] = Value + (PerLevel[Key] * math.max(Level - 1, 0))
		else
			Converted[Key] = Value
		end
	end	
	
	return table.freeze(Converted)
end

function EnemyData:GetEnemyData(Character: string): Types.CharacterData
	if EnemyData.__Saved[Character] == nil then
		return EnemyData.__Saved['Template']
	end
	
	return EnemyData.__Saved[Character]
end

function EnemyData:GetIdForEnemy(Name: string)
	return table.find(EnemyData.__Ids, Name)
end

function EnemyData:GetEnemyFromId(Id: number)
	return EnemyData.__Ids[Id]
end

return EnemyData
