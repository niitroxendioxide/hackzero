--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local Replicator = require(Client.Libraries.Replicator)

--
local Controller = {
	__Replicators = {},
	__Ping = 0,
}

-- Privates
local function HandleReplication(Buffer: buffer, ...)
	local Action = buffer.readu8(Buffer, 0)

	for Key, Value in GameEnum.Replication do
		if Value == Action and Controller.__Replicators[Key] then
			local ReplicatorController = Controller.__Replicators[Key]
			local Method = ReplicatorController[Key]

			Method(ReplicatorController, Buffer, ...)
		end
	end
end

-- Public
function Controller:Init()
	for _, Module in script:GetChildren() do
		local Success, Required = pcall(require, Module)

		if Success then
			for Method in Required do
				Controller.__Replicators[Method] = Required
			end
		end
	end

	Network:On('Replicate', HandleReplication)
	Network:On('ReliableReplication', HandleReplication)

	Controller:ConnectPing()
end

-- @ Action: GameEnum.Replication
function Controller:Replicate(Action: number, ...)
	return Replicator:Replicate(Action, ...)
end

function Controller:DeclareDead()
	Network:Fire('Match', GameEnum.MatchEvents.PlayerDied)
end

function Controller:ConnectPing()
	task.spawn(function()
		while true do
			local Sent, Receive = Network:GetPing()
			Controller.__Ping = Receive + Sent
			Replicator.__Ping = Controller.__Ping

			task.wait(.5)
		end
	end)
end

function Controller:GetPing()
	return Controller.__Ping;
end


return Controller
