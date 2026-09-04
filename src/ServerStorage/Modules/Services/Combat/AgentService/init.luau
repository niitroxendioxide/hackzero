--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Signal = require(Shared.Utility.Signal)
local Network = require(Shared.Network)
local Statics = require(Shared.Database.Statics)
local Math = require(Shared.Utility.Math)
local AgentTypes = require(Shared.Types.Agents)

local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
type Player_Data = {Active: number, Characters: {AgentTypes.ServerAgentClass}}

local Service = {
	__Characters = {} :: {[Player]: Player_Data},
	--[[
		Opcode -> handler. This replaces the old dispatch, which scanned
		GameEnum.Replication for a key whose name matched a method on this
		table -- and so quietly exposed AddAgent, RemoveAgent and PivotTo to
		anything a client cared to send. Only what is registered here is
		reachable from the network.
	]]
	__Handlers = {} :: {[number]: (any, Player, buffer, ...any) -> ()},
	AgentAdded = Signal.new() :: Signal.ScriptSignal<AgentTypes.ServerAgentClass>,
}

--[[
	Submodules attach their public methods to Service and register their packet
	handlers here.

	They must NOT expose an `Init` field: Framework:Init walks Services with
	GetDescendants and would initialise each of them on its own thread in
	undefined order. `Start` is called explicitly below instead.
]]
local SUBMODULES = {'Movement', 'Switching', 'Sync'}

function Service:RegisterHandler(Action: number, Handler: (any, Player, buffer, ...any) -> ())
	Service.__Handlers[Action] = Handler
end

function Service:Init()
	Network.new('Replicate', 'Unreliable')
	Network.new('ReliableReplication', 'Event')

	Network:On('Replicate', Service.ReplicateEvent)
	Network:On('ReliableReplication', Service.ReplicateEvent)

	RunService.Heartbeat:Connect(function(Delta: number)
		for _, PlayerList in AgentLibrary.__Players do
			for _, Agent in PlayerList do
				Agent:Update(Delta)
			end
		end
	end)
end

function Service:Create(Player: Player)
	Service.__Characters[Player] = {
		Active = 1,
		Characters = {},
	}
end

function Service:Get(Player: Player): Player_Data
	if not Service.__Characters[Player] then
		Service:Create(Player)
	end

	return Service.__Characters[Player]
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer, ...)
	local Handler = Service.__Handlers[buffer.readu8(ClientBuffer, 0)]
	if not Handler then
		return
	end

	if Service:GetCurrentCharacter(Player) == nil then
		return
	end

	Handler(Service, Player, ClientBuffer, ...)
end

function Service:AddAgent(Player: Player, AgentClass: AgentTypes.ServerAgentClass, Target: Player?, OverrideArtifacts: {}?)
	local Data = Service:Get(Player)
	for _, Character in Data.Characters do
		if Character.Name == AgentClass.Name then
			return
		end
	end

	-- Kept in lockstep with AgentLibrary's own cap. The two lists are indexed in
	-- parallel (GetIdForPlayer resolves against the library), so letting one grow
	-- past the other would silently misaddress every movement packet.
	if #Data.Characters >= Statics.Max_Team_Size then
		warn('Cannot add character to team, reason: Team is already full')

		return
	end

	table.insert(Data.Characters, AgentClass)

	Replicator:AddAgent(Player, AgentClass, Target, nil, OverrideArtifacts)
	Service.AgentAdded:Fire(AgentClass)
	AgentLibrary:Add(Player:GetAttribute("ReplicationId") :: number, AgentClass)
end

function Service:RemoveAgent(Player: Player, Name: string)
	local Data = Service:Get(Player)

	for key, Agent in Data.Characters do
		if Agent.Name == Name then
			AgentLibrary:Remove( Player:GetAttribute("ReplicationId") :: number, Agent)
			table.remove(Data.Characters, key)
		end
	end

	Replicator:RemoveAgent(Player, Name)
end

function Service:GetCurrentCharacter(Player: Player): AgentTypes.ServerAgentClass?
	local Data = Service:Get(Player)

	return Data.Characters[Data.Active]
end

function Service:GetCharacters(Player: Player)
	local Data = Service:Get(Player)

	return Data.Characters
end

function Service:GetAgent(Player: Player, AgentId: number): AgentTypes.ServerAgentClass?
	return Service:Get(Player).Characters[AgentId]
end

function Service:GetAgentId(Player: Player, Agent: AgentTypes.ServerAgentClass): number?
	for Id, Candidate in Service:Get(Player).Characters do
		if Candidate == Agent then
			return Id
		end
	end

	return nil
end

--[[
	Build the byte broadcast alongside Move/Stop, describing the given agent as
	the server currently sees it.
]]
function Service:GetMovementByte(Player: Player, Agent: AgentTypes.ServerAgentClass, Moving: boolean?): number?
	local AgentId = Service:GetAgentId(Player, Agent)
	if not AgentId then
		return nil
	end

	local IsMoving = if Moving == nil then Agent:IsMoving() == true else Moving

	return Math:EncodeMovementByte(AgentId, IsMoving, Agent:GetKey("Sprint") == true, Agent:GetKey("Jog") == true)
end

-- Attached at require time rather than in Init: Framework initialises services
-- on separate threads in undefined order, and callers such as AbilityService and
-- Mission expect Stop/SnapTo/CharacterSwitch/Sync to already be here.
for _, Name in SUBMODULES do
	require(script[Name]).Start(Service)
end

return Service
