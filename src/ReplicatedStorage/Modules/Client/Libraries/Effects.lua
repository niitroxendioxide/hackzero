--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client

--

local Effects = {
	__Cached = {}
}

function Effects:Init()
	for _, Effect in Client.Components.VFX:GetDescendants() do
		if Effect:IsA('ModuleScript') then
			local Success, Required = pcall(require, Effect)

			if Success then
				Effects.__Cached[Effect.Name] = Required
			else
				warn('Error when loading effect component:', Effect.Name)
			end
		end
	end
end

function Effects:Play(Name: string, ...)
	--
	local Module = Effects.__Cached[Name]

	if not Module then
		return
	end

	local Args = {...};

	task.spawn(function()
		Module(table.unpack(Args))

	end)
end

return Effects
