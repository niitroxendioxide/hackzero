--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Statics = require(Shared.Database.Statics)
local Enemies = require(Shared.Libraries.Enemies)
local AssistUtil = require(Shared.Utility.Assist)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Switching = {}

-- Flag bits in byte 5 of the CharacterSwitch packet.
local FLAG_BACKWARD = 0x01
local FLAG_FORCE_ROTATE = 0x02

function Switching.Start(Service)
	--[[
		Apply a character switch requested by the client.

		The destination is recomputed here rather than trusted, but from the same
		inputs the client predicted with: the Seed in byte 4, and the direction
		and force-rotate flags in byte 5. AssistUtil draws its side offsets from
		a Random built on that seed, so both sides land on the identical CFrame.
		Before this, both sides drew from a shared JobId-seeded singleton whose
		stream position diverges -- which is why an assist switch put the agent
		on a different side on each machine.

		@param p_Target Enemy supplied by an internal caller (chain attacks).
		@param p_ForceRotate Forces the "approach from the far side" branch.
	]]
	function Service:CharacterSwitch(Player: Player, Buffer: buffer, p_Target, p_ForceRotate: boolean?)
		local Data = Service:Get(Player)
		local NewAgentIndex = buffer.readu8(Buffer, 1)

		local PreviousAgent = Data.Characters[Data.Active]
		local NewAgent = Data.Characters[NewAgentIndex]

		-- An out of range index used to error on the IsAlive call below.
		if not PreviousAgent or not NewAgent or not NewAgent:IsAlive() then
			return
		end

		--- rotation vector math
		local Angle = math.rad(buffer.readi16(Buffer, 2) / 180)
		local RebuiltRotationVector = vector.create(math.sin(Angle), 0, math.cos(Angle))

		local Seed = buffer.readu8(Buffer, 4)
		local Flags = buffer.readu8(Buffer, 5)
		local Direction = if bit32.band(Flags, FLAG_BACKWARD) ~= 0 then -1 else 1
		local ForceRotate = p_ForceRotate == true or bit32.band(Flags, FLAG_FORCE_ROTATE) ~= 0

		--- switching & other
		Data.Active = NewAgentIndex

		local WasMoving = PreviousAgent:IsMoving()
		local MarkedAgentStruct = PreviousAgent:GetMarkedTarget()
		local Target = p_Target
		if MarkedAgentStruct ~= nil and MarkedAgentStruct.TargetId ~= nil then
			Target = Enemies:GetEnemy(MarkedAgentStruct.TargetId)
		end

		local SwitchCFrame = AssistUtil:CalculateSwitchCFrame(PreviousAgent, Direction, Target, ForceRotate, Seed)

		-- CalculateSwitchCFrame is pure now, so the outgoing agent is stopped here.
		PreviousAgent:Stop()

		-- Data.Active above is the single writer; the per-agent flag is derived
		-- from it here so the two registries cannot drift.
		for _, PlayerAgent in Service:GetCharacters(Player) do
			PlayerAgent:SetActive(PlayerAgent == NewAgent)
		end

		if not NewAgent:HasTag("CharacterStatic") then
			NewAgent:PivotTo(SwitchCFrame, true)
			NewAgent:Rotate(RebuiltRotationVector)

			if not Target then
				NewAgent:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, Statics.Dodge_Active_Time)
				NewAgent:ImpulseForward(Statics.Switch_Character_Dash_Strength, 0.75)
			end

			if WasMoving then
				Service:Move(Player)
			end
		end

		-- Reliable, and sent to the owner too: for them the CFrame is a
		-- correction against what they already predicted, which the client
		-- discards when the prediction was right.
		Replicator:CharacterSwitch(Player, NewAgentIndex, Target and Target:GetId(), NewAgent:GetPivot())
		Replicator:Rotate(Player, NewAgentIndex, RebuiltRotationVector)

		--- Events
		local AgentGearManager = NewAgent:GetGearManager()
		AgentGearManager:RunEventHooks(GameEnum.ArtifactEvents.AgentSwitchedIn, {
			Agent = NewAgent,
			Previous = PreviousAgent,
		})

		---
		if MarkedAgentStruct then
			if MarkedAgentStruct.AssistCharacterId == NewAgentIndex then
				MarkedAgentStruct.Accepted:Fire()
			end

			MarkedAgentStruct.Accepted:DisconnectAll()

			-- Clear the whole mark, including its expiry thread. Nilling only
			-- TargetId left the struct and its timer alive.
			PreviousAgent:MarkTarget(nil)
		end
	end

	Service:RegisterHandler(GameEnum.Replication.CharacterSwitch, function(_, Player: Player, Buffer: buffer)
		Service:CharacterSwitch(Player, Buffer)
	end)
end

return Switching
