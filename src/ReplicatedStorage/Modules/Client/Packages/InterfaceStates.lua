--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Fusion = require(Client.Libraries.Fusion)

--
local Scope = Fusion.scoped({})
local module = {
	Energy = Fusion.Value(Scope, 0),
	Health = Fusion.Value(Scope, 100),
	Max_Health = Fusion.Value(Scope, 100),
	Characters = Fusion.Value(Scope, {})
}

return module
