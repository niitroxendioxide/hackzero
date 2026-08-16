--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Fusion = require(Client.Libraries.Fusion)
local Signal = require(Shared.Utility.Signal)

--
local Scope = Fusion.scoped({})
local module = {
	Energy = {
		[1] = Fusion.Value(Scope, 0),
		[2] = Fusion.Value(Scope, 0),
		[3] = Fusion.Value(Scope, 0),
	},

	UltBar = {
		[1] = Fusion.Value(Scope, 0),
		[2] = Fusion.Value(Scope, 0),
		[3] = Fusion.Value(Scope, 0),
	},

	EffectAdded = Signal.new(),
	EffectReset = Signal.new(),
	EffectRemoved = Signal.new(),

	Health = {
		[1] = Fusion.Value(Scope, 1),
		[2] = Fusion.Value(Scope, 1),
		[3] = Fusion.Value(Scope, 1)
	},
	Characters = Fusion.Value(Scope, {})
}

return module
