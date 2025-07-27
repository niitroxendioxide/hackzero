--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Data)

--
local Companions = {
	__Saved = {} :: {[string]: Types.CompanionData},
	__Ids = {},
}

function Companions:Init()
	for _, Module in script:GetChildren() do
		local Success, Companion = pcall(require, Module)

		if Success then
			Companions.__Saved[Module.Name] = table.freeze(Companion)

			table.insert(Companions.__Ids, Module.Name)
		else
			warn('Error on character data for:', Module.Name)
		end
	end

	table.sort(Companions.__Ids, function(a, b)
		return a < b
	end)

	table.freeze(Companions.__Ids)
end

function Companions:GetAttack(Name: string): Types.CompanionAttack
	local AccessedData = Companions:GetCompanionData(Name)

	return AccessedData.Attack
end

function Companions:GetPasive(Name: string): Types.CompanionPassive
	local AccessedData = Companions:GetCompanionData(Name)

	return AccessedData.Passive
end

function Companions:GetStatsAtLevel(Name: string, Level: number)
	local ObtainedData = Companions:GetCompanionData(Name)

	local Converted = {}

	for Key, Value in ObtainedData.Stats do
		local PerLevel = ObtainedData.LevelStats

		if PerLevel[Key] then
			Converted[Key] = Value + (PerLevel[Key] * math.max(Level - 1, 0))
		else
			Converted[Key] = Value
		end
	end

	return table.freeze(Converted)
end

function Companions:GetCompanionData(Companion: string): Types.CompanionData
	if Companions.__Saved[Companion] == nil then
		return Companions.__Saved['Template']
	end

	return Companions.__Saved[Companion]
end

function Companions:GetIdFor(Name: string)
	return table.find(Companions.__Ids, Name)
end

function Companions:GetFromId(Id: number)
	return Companions.__Ids[Id]
end

function Companions:GetAllNames(): {string}
	local List = {}
	for _, Name in Companions.__Ids do
		table.insert(List, Name)
	end

	return List
end

return Companions
