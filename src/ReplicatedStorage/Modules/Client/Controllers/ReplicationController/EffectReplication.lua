--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

--local _GameEnum = require(Shared.GameEnum)
local AgentsLib = require(Client.Libraries.Characters)
local EffectsLib = require(Client.Libraries.Effects)

--
local Controller = {}

function Controller:PlayVisualEffect(MainBuffer: buffer, ...: any): ()
	local EffectName = buffer.readstring(MainBuffer, 1, buffer.len(MainBuffer) - 1)
	local Args = {...}

	for key, Arg in Args do
		if typeof(Arg) == 'buffer' then
			local AgentId = buffer.readu8(Arg, 0)
			local PlayerId = buffer.readu8(Arg, 1)

			local AgentObject = AgentsLib:GetAgent(PlayerId, AgentId)

			Args[key] = AgentObject
		end
	end

	EffectsLib:Play(EffectName, table.unpack(Args))
end

return Controller