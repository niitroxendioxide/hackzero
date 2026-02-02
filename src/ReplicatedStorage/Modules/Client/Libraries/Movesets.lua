--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local MovesetFolder = Client.Components.Movesets
local SwapSkill = require(MovesetFolder.Swap)

--
local Movesets = {
	__Cache = {}
}

function Movesets:Init()
	for _, Moveset in MovesetFolder:GetDescendants() do
		if Moveset.Name == 'Swap' then
			continue
		end

		if Moveset:IsA('ModuleScript') and Moveset.Parent:IsA('Folder') then
			local Success, Required = pcall(require, Moveset)

			if Success then
				Required:Assign('Swap Back', SwapSkill)
				Required:Assign('Swap Forth', SwapSkill)
				Movesets.__Cache[Moveset.Name] = Required
			end
		end
	end
end

function Movesets:Get(Name: string, default): Types.MovesetClass
	return Movesets.__Cache[Name] or Movesets.__Cache[default or 'Template']
end

function Movesets:RunFromTemplate(Move: string, ...)
	local Template = Movesets.__Cache.Template :: Types.MovesetClass

	Template:Begin(Move, ...)
end


return Movesets
