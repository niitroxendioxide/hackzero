--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local EffectsLib = require(Client.Libraries.Effects)

local LocalUserId = Players.LocalPlayer.UserId

--
local Controller = {}

function Controller:Effect(Buffer: buffer, ...)
	local Args = {...}
	
	EffectsLib:Play(...)
end

return Controller