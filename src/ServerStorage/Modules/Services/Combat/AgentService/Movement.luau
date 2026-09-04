--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Math = require(Shared.Utility.Math)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Movement = {}

local AREA_SIZE_MODIFIER = 1.25


local function ResolveAgent(Service, Player: Player, Buffer: buffer)
	local AgentId, Moving, Sprint, Jog = Math:DecodeMovementByte(buffer.readu8(Buffer, 1))
	local Agent = Service:GetAgent(Player, AgentId)

	if not Agent then
		return nil
	end

	return Agent, AgentId, Moving, Sprint, Jog
end

function Movement.Start(Service)
	local function HandleMovement(_, Player: Player, Buffer: buffer)
		local Agent, AgentId, Moving, Sprint, Jog = ResolveAgent(Service, Player, Buffer)
		if not Agent then
			return
		end

		Agent:SetKey("Sprint", Sprint)
		Agent:SetKey("Jog", Jog)

		local Attacking = Agent:GetState() == 'Attacking'
		local ShouldMove = Moving and not Attacking

		if ShouldMove then
			Agent:Move()
		else
			Agent:Stop()
		end

		if Moving and Attacking then
			return
		end

		local MovementByte = Math:EncodeMovementByte(AgentId, ShouldMove, Sprint, Jog)

		if ShouldMove then
			Replicator:Move(Player, MovementByte)
		else
			Replicator:Stop(Player, MovementByte)
		end
	end

	Service:RegisterHandler(GameEnum.Replication.Move, HandleMovement)
	Service:RegisterHandler(GameEnum.Replication.Stop, HandleMovement)

	Service:RegisterHandler(GameEnum.Replication.Rotate, function(_, Player: Player, Buffer: buffer)
		local Agent, AgentId = ResolveAgent(Service, Player, Buffer)
		if not Agent then
			return
		end

		local Angle = buffer.readi16(Buffer, 2) / 5133
		local Rebuilt = Vector3.new(math.sin(Angle), 0, math.cos(Angle))

		Agent:Rotate(Rebuilt)

		Replicator:Rotate(Player, AgentId :: number, Rebuilt)
	end)

	Service:RegisterHandler(GameEnum.Replication.PivotTo, function(_, Player: Player, Buffer: buffer)
		local Agent = ResolveAgent(Service, Player, Buffer)
		if not Agent then
			return
		end

		local At = Math:DecodeCFrame(Buffer, 2)

		local LimitArea = Agent:GetLimitArea()
		if LimitArea then
			At = Math:ClampPointToBox(At, LimitArea, AREA_SIZE_MODIFIER) :: CFrame
		end

		Agent:PivotTo(At, true)

		Replicator:PivotTo(Agent, At)
	end)

	--[[
		Sprint/Jog now ride in the movement byte, so this is no longer sent by
		the client. It stays for internal callers that flip a key server side.
	]]
	function Service:KeySwitch(Player: Player, Key: string, Value: boolean)
		local Data = Service:Get(Player)

		for AgentId, Character in Data.Characters do
			Character:SetKey(Key, Value)

			local MovementByte = Math:EncodeMovementByte(AgentId, Character:IsMoving() == true, Character:GetKey("Sprint") == true, Character:GetKey("Jog") == true)

			if Character:IsMoving() then
				Character:Move()
				Replicator:Move(Player, MovementByte)
			end
		end

		Replicator:KeySwitch(Player, Key, Value)
	end

	--[[
		Server initiated stop of the player's active agent (used by AbilityService
		when a skill takes over).
	]]
	function Service:Stop(Player: Player)
		local Agent = Service:GetCurrentCharacter(Player)
		if not Agent then
			return
		end

		Agent:Stop()

		local MovementByte = Service:GetMovementByte(Player, Agent, false)
		if MovementByte then
			Replicator:Stop(Player, MovementByte)
		end
	end

	--[[
		Server authoritative teleport. Unlike a replicated correction this is
		meant to be instant, so it is sent to the owner as well.
	]]
	function Service:SnapTo(Player: Player, CF: CFrame)
		local Agent = Service:GetCurrentCharacter(Player)
		if not Agent then
			return
		end

		local At = CFrame.lookAlong(CF.Position, Agent:GetPivot().LookVector)

		-- `true` suppresses ServerAgentClass.PivotTo's own replication; the two
		-- explicit sends below cover the owner and everyone else exactly once.
		Agent:PivotTo(At, true)

		Replicator:PivotTo(Agent, At, Player)
		Replicator:PivotTo(Agent, At)
	end

	--[[
		Move the player's active agent from server code, with no packet involved.
	]]
	function Service:Move(Player: Player)
		local Agent = Service:GetCurrentCharacter(Player)
		if not Agent or Agent:GetState() == 'Attacking' then
			return
		end

		Agent:Move()

		local MovementByte = Service:GetMovementByte(Player, Agent, true)
		if MovementByte then
			Replicator:Move(Player, MovementByte)
		end
	end
end

return Movement
