--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Server = ServerStorage.Modules

local Types = require(Shared.Types.Abilities)
local MovesetFolder = Server.Components.Movesets

--
local Movesets = {
	__Cache = {}
}

function Movesets:Init()
	for _, Moveset in MovesetFolder:GetDescendants() do
		if Moveset:IsA('ModuleScript') and Moveset.Parent:IsA('Folder') then
			local Success, Required = pcall(require, Moveset)

			if Success then
				Movesets.__Cache[Moveset.Name] = Required
			end
		end
	end
end

function Movesets:Get(Name: string, default): Types.MovesetClass
	if not Movesets.__Cache[Name] then
		return Movesets.__Cache[default and 'Saiyan' or 'Saiyan']
	end

	return Movesets.__Cache[Name]
end

function Movesets:RunFromTemplate(Move: string, ...)
	local Template = Movesets.__Cache.Template :: Types.MovesetClass

	Template:Begin(Move, ...)
end

function Movesets:GetAll(): {Types.MovesetClass}
	return Movesets.__Cache
end

return Movesets
