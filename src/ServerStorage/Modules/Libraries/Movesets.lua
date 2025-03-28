--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Server = ServerStorage.Modules

local Types = require(Shared.Types)
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
	return Movesets.__Cache[Name] or Movesets.__Cache[default and 'Saiyan' or 'Goku']
end

return Movesets
