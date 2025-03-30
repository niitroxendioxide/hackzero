--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local CharacterData = {
	__Saved = {} :: {[string]: Types.CharacterData},
	__Ids = {},
}

function CharacterData:Init()
	for _, Module in script:GetChildren() do
		local Success, Character = pcall(require, Module)

		if Success then
			CharacterData.__Saved[Module.Name] = table.freeze(Character)
			
			table.insert(CharacterData.__Ids, Module.Name)
		else
			warn('Error on character data for:', Module.Name)
		end
	end
	
	table.sort(CharacterData.__Ids, function(a, b)
		return a < b
	end)
	
	table.freeze(CharacterData.__Ids)
end

function CharacterData:GetStats(Character: string): Types.CharacterStats
	local AccessedData = CharacterData:GetCharacterData(Character)
	
	return AccessedData.Stats
end

function CharacterData:GetMovesetData(Character: string): Types.CharacterStats
	local AccessedData = CharacterData:GetCharacterData(Character)

	return AccessedData.Moveset_Data
end


function CharacterData:GetStatsAtLevel(Character: string, Level: number)
	local ObtainedData = CharacterData:GetCharacterData(Character)
	
	local Converted = {}
	
	for Key, Value in ObtainedData.Stats do
		local PerLevel = ObtainedData.Level_Stats
		
		if PerLevel[Key] then
			Converted[Key] = Value + (PerLevel[Key] * math.max(Level - 1, 0))
		else
			Converted[Key] = Value
		end
	end	
	
	return table.freeze(Converted)
end

function CharacterData:GetAppearanceData(Character: string): Types.CharacterAppearanceData
	local AccessedData = CharacterData:GetCharacterData(Character)
	
	return AccessedData.Appearance
end

function CharacterData:GetSpeedStats(Character: string): Types.CharacterStats
	local AccessedData = CharacterData:GetCharacterData(Character)

	return {
		Jog_Speed = AccessedData.Stats.Jog_Speed,
		Walk_Speed = AccessedData.Stats.Walk_Speed,
		Sprint_Speed = AccessedData.Stats.Sprint_Speed,
	}
end

function CharacterData:GetCharacterData(Character: string): Types.CharacterData
	if CharacterData.__Saved[Character] == nil then
		return CharacterData.__Saved['Template']
	end
	
	return CharacterData.__Saved[Character]
end

function CharacterData:GetIdForCharacter(Name: string)
	return table.find(CharacterData.__Ids, Name)
end

function CharacterData:GetCharacterFromId(Id: number)
	return CharacterData.__Ids[Id]
end


return CharacterData
