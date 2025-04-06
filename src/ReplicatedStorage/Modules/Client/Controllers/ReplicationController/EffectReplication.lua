--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local _GameEnum = require(Shared.GameEnum)
local EffectsLib = require(Client.Libraries.Effects)

--
local Controller = {}

function Controller:Effect(Buffer: buffer, ...): ()
	local EffectId = buffer.readu16(Buffer, 1)
	local Args = {...}

	EffectsLib:Play(EffectId, table.unpack(Args))
end

return Controller