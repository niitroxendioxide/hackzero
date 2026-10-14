---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client

local LibEffects = require(Client.Libraries.Effects)

---
return function(Agent)
	if Agent == nil then
		return
	end

	LibEffects:Play('Indicator', Agent, {Text = 'Corrupted!', Affliction = 'Corrupted', Critical = true})
end
