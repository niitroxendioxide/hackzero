local Framework = {
	Debug = game:GetService('RunService'):IsStudio(),
}

function Framework:Init(...)
	for _, Folder in {...} do
		for _, Module in Folder:GetChildren() do
			local Success, Required = pcall(require, Module)
			
			if not Success and Framework.Debug then
				warn('Error when loading module:'..Module.Name, ' ->', Required)
				
				continue
			end
			
			if typeof(Required) == 'table' and Required.Init and not Required.Initialized then
				task.spawn(function()
					local Success, ErMsg = pcall(Required.Init, Required)

					if not Success and Framework.Debug then
						warn(`:Init() method for module {Module.Name} raised error: {ErMsg}`)
					elseif Success then
						Required.Initialized = true
					end
				end)
			end
		end
	end
end

return Framework
