--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Fusion = require(Client.Libraries.Fusion)

--
local Scope = Fusion.scoped({})
local module = {
	Energy = {
		[1] = Fusion.Value(Scope, 0),
		[2] = Fusion.Value(Scope, 0),
		[3] = Fusion.Value(Scope, 0),
	},
	Health = Fusion.Value(Scope, 100),
	Max_Health = Fusion.Value(Scope, 100),
	Characters = Fusion.Value(Scope, {})
}

return module
