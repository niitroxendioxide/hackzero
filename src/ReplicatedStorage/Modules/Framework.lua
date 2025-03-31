local Framework = {
	Debug = game:GetService('RunService'):IsStudio(),
}

function Framework:Init(...)
	for _, Child: ModuleScript | Folder in {...} do
		if Child:IsA("ModuleScript") then
			Framework:LoadModule(Child)
		else
			for _, Module in Child:GetChildren() do
				Framework:LoadModule(Module)
			end
		end
	end
end

function Framework:LoadModule(Module: ModuleScript)
	local Success, Required = pcall(require, Module)

	if not Success and Framework.Debug then
		warn('Error when loading module:'..Module.Name, ' ->', Required)

		return
	end

	if typeof(Required) == 'table' and Required.Init and not Required.Initialized then
		task.spawn(function()
			local ErMsg;
			Success, ErMsg = pcall(Required.Init, Required)

			if not Success and Framework.Debug then
				warn(`:Init() method for module {Module.Name} raised error: {ErMsg}`)
			elseif Success then
				Required.Initialized = true
			end
		end)
	end
end

return Framework
