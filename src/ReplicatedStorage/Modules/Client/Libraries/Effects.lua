--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

--
local Mock = require(Shared.Utility.Mock)
local Settings = require(Client.Packages.Settings)

local Non_Effects = {'Indicator', 'EnemyStats', 'Barrier'}
local Effects = {
	__Cached = {}
}

function Effects:Init()
	for _, Effect in Client.Components.VFX:GetDescendants() do
		if Effect:IsA('ModuleScript') then
			local Success, Required = pcall(require, Effect)

			if Success and typeof(Required) == 'function' then
				Effects.__Cached[Effect.Name] = Required
			else
				warn('Error when loading effect component:', Effect.Name)
			end
		end
	end
end

function Effects:Play(Name: string, ...)
	--
	local HasVFXEnabled = Settings:Get("VisualEffects", "Graphics")
	if not table.find(Non_Effects, Name) and not(HasVFXEnabled) then
		return
	end

	local Module = Effects.__Cached[Name]

	if not Module then
		return
	end

	local Args = {...};

	task.spawn(function()
		Module(table.unpack(Args))

	end)
end

function Effects:PlaySerial(Name: string, ...)
	--
	local HasVFXEnabled = Settings:Get("VisualEffects", "Graphics")
	if not(HasVFXEnabled) then
		return Mock;
	end

	local Module = Effects.__Cached[Name]

	if not Module then
		return
	end

	local Args = {...};

	return Module(table.unpack(Args))
end

return Effects
