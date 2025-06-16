--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local DataTypes = require(Shared.Types.Data)

--
local Items = {
	__Stored = {} :: DataTypes.ItemData,
	__Ids = {},
}

function Items:Init()
	for _, ItemModule in script:GetChildren() do
		local Success, ItemData = pcall(require, ItemModule)

		if Success then
			Items.__Stored[ItemModule.Name] = table.freeze(ItemData)

			table.insert(Items.__Ids, ItemModule.Name)
		else
			warn('Error on Gear data for:', ItemModule.Name)
		end
	end

	table.sort(Items.__Ids, function(a, b)
		return a > b
	end)
end

function Items:GetItemData(Name: string): DataTypes.ItemData
	local SavedData = Items.__Stored[Name]

	return SavedData
end

function Items:Verify(Name: string): boolean
	return Items:GetItemData(Name) ~= nil
end

function Items:GetIdFor(Name: string): number?
	return table.find(Items.__Ids, Name)
end

function Items:GetFromId(Id: number): string
	return Items.__Ids[Id]
end

return Items