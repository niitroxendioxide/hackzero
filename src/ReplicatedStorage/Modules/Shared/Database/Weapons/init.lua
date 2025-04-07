--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local Weapons = {
	__Stored = {} :: Types.Weapon_Data,
	__Ids = {},
}

function Weapons:Init()
	for _, WeaponModule in script:GetChildren() do
		local Success, Weapon_Data = pcall(require, WeaponModule)

		if Success then
			Weapons.__Stored[WeaponModule.Name] = table.freeze(Weapon_Data)

			table.insert(Weapons.__Ids, WeaponModule.Name)
		else
			warn('Error on character data for:', WeaponModule.Name)
		end
	end
end

function Weapons:GetWeaponData(Name: string): Types.Weapon_Data
	local SavedData = Weapons.__Stored[Name]

	return SavedData
end

function Weapons:GetPassive(Name: string)
	local WeaponData = Weapons:GetWeaponData(Name)

	return WeaponData.Passive_Description;
end

function Weapons:GetWeaponsByRarity(Name: string)
	local WeaponData = Weapons:GetWeaponData(Name)

	return WeaponData.Passive_Description;
end

function Weapons:Verify(Name: string): boolean
    local Data = Weapons:GetWeaponData(Name)

    return Data ~= nil
end

function Weapons:GetIdForWeapon(Name: string): number
	return table.find(Weapons.__Ids, Name) :: number
end

function Weapons:GetWeaponFromId(Id: number): string
	if Id == 0 then
		return "None"
	end

	return Weapons.__Ids[Id]
end


return Weapons
