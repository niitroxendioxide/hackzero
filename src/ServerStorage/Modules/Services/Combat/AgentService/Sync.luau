--
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService('ServerStorage')

local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Sync = {}

-- Seconds between full position snapshots. This is a correction heartbeat, not
-- the primary position channel: the owning client sends its own pose far more
-- often, and clients smooth whatever this disagrees with.
local BATCH_SYNC_INTERVAL = 2

function Sync.Start(Service)
	local BatchSyncClock = os.clock()

	RunService.Heartbeat:Connect(function()
		if (os.clock() - BatchSyncClock) < BATCH_SYNC_INTERVAL then
			return
		end

		BatchSyncClock = os.clock()

		for _, PlayerList in AgentLibrary.__Players do
			for _, Agent in PlayerList do
				Replicator:PivotTo(Agent, Agent:GetPivot())
			end
		end
	end)

	--[[
		Replay one player's agents to a client that has just joined or respawned.
	]]
	function Service:Sync(Player: Player, Target: Player)
		local CurrentCharacter = Service:GetCurrentCharacter(Player)

		if not CurrentCharacter then
			return
		end

		local ActiveId = Service:GetAgentId(Player, CurrentCharacter) or 1

		Replicator:AddAgent(Player, CurrentCharacter, Target, CurrentCharacter:GetPivot())

		for _, Character in Service:GetCharacters(Player) do
			if Character ~= CurrentCharacter then
				Replicator:AddAgent(Player, Character, Target)
			end
		end

		Replicator:Rotate(Player, ActiveId, CurrentCharacter.__Character.__Rotation, Target)

		local MovementByte = Service:GetMovementByte(Player, CurrentCharacter)
		if MovementByte and CurrentCharacter:IsMoving() then
			Replicator:Move(Player, MovementByte, Target)
		end

		-- Order matters and must match AgentClass:SyncVelocities on the client.
		-- MovementVelocity is deliberately not sent: it is a Vector3 here and a
		-- scalar there, so it cannot be copied across.
		local Controller = CurrentCharacter.__Character

		Replicator:SyncVelocities(Player, Target,
			Controller.__Velocity,
			Controller.__LastMovementVelocity,
			Controller.__SurfaceVelocity
		)
	end
end

return Sync
