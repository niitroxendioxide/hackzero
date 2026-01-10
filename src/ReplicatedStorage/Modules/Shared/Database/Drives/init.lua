--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local Drives = {
	__Stored = {} :: Types.Drive_Data,
	__Ids = {},
}

function Drives:Init()
	for _, DriveModule in script:GetChildren() do
		local Success, Drive_Data = pcall(require, DriveModule)

		if Success then
			Drives.__Stored[DriveModule.Name] = table.freeze(Drive_Data)

			table.insert(Drives.__Ids, DriveModule.Name)
		else
			warn('Error on character data for:', DriveModule.Name)
		end
	end

	table.sort(Drives.__Ids, function(a, b)
		return a > b
	end)
end

function Drives:GetAll()
	return Drives.__Ids
end


function Drives:Get(Name: string)
	return Drives:GetDriveData(Name)
end

function Drives:GetDriveData(Name: string): Types.Drive_Data
	local SavedData = Drives.__Stored[Name]

	return SavedData
end

function Drives:GetPassive(Name: string)
	local DriveData = Drives:GetDriveData(Name)

	return DriveData.Passive_Description;
end

function Drives:GetDrivesByRarity(Name: string)
	local DriveData = Drives:GetDriveData(Name)

	return DriveData.Passive_Description;
end

function Drives:Verify(Name: string): boolean
    local Data = Drives:GetDriveData(Name)

    return Data ~= nil
end

function Drives:GetIdForDrive(Name: string): number
	return table.find(Drives.__Ids, Name) :: number
end

function Drives:GetDriveFromId(Id: number): string
	if Id == 0 then
		return "None"
	end

	return Drives.__Ids[Id]
end


return Drives
