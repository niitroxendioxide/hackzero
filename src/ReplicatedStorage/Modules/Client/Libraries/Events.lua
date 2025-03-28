--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Signal = require(Shared.Utility.Signal)

--
local Events = {

	CharacterChanged = Signal.new(),
	
} :: {[string]: Signal.ScriptSignal}

return Events
