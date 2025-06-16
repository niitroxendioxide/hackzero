--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local DataTypes = require(Shared.Types.Data)

--
local Gear = {
	__Stored = {} :: DataTypes.GearData,
	__Ids = {},
}

function Gear:Init()
	for _, GearModule in script:GetChildren() do
		local Success, GearData = pcall(require, GearModule)

		if Success then
			Gear.__Stored[GearModule.Name] = table.freeze(GearData)

			table.insert(Gear.__Ids, GearModule.Name)
		else
			warn('Error on Gear data for:', GearModule.Name)
		end
	end

	table.sort(Gear.__Ids, function(a, b)
		return a > b
	end)
end

function Gear:GetGearData(Name: string): DataTypes.GearData
	local SavedData = Gear.__Stored[Name]

	return SavedData
end

function Gear:Verify(Name: string): boolean
	return Gear:GetGearData(Name) ~= nil
end

function Gear:GetIdFor(Name: string): number?
	return table.find(Gear.__Ids, Name)
end

function Gear:GetFromId(Id: number): string
	return Gear.__Ids[Id]
end

return Gear