--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
local AgentTypes = require(Shared.Types.Agents)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local AssistUtil = require(Shared.Utility.Assist)

local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
type Player_Data = {Active: number, Characters: {AgentTypes.ServerAgentClass}}

local Service = {
	__Characters = {} :: {[Player]: Player_Data},
}

function Service:Init()
	Network.new('Replicate', 'Unreliable')
	Network.new('ReliableReplication', 'Event')

	Network:On('Replicate', Service.ReplicateEvent)
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
	local Type = buffer.readu8(ClientBuffer, 0)

	for Action, Value in GameEnum.Replication do
		if Value == Type and Service[Action] then
			if Service:GetCurrentCharacter(Player) == nil then
				print("Request rejected. Player not initialized")
				return;
			end

			Service[Action](Service, Player, ClientBuffer, ...)
		end
	end
end

function Service:AddAgent(Player: Player, AgentClass: AgentTypes.ServerAgentClass, Target: Player?)
	local Data = Service:Get(Player)
	for _, Character in Data.Characters do
		if Character.Name == AgentClass.Name then
			return
		end
	end

	table.insert(Data.Characters, AgentClass)
	--
	Replicator:AddAgent(Player, AgentClass, Target)
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

function Service:Move(Player: Player, Buffer: buffer?)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)
	if Buffer and buffer.len(Buffer) > 1 then
		local Sprinting = buffer.readu8(Buffer, 1) == 1
		local Jogging = buffer.readu8(Buffer, 2) == 1

		local Data = Service:Get(Player)

		for _, Character in Data.Characters do
			Character:SetKey("Sprint", Sprinting)
			Character:SetKey("Jog", Jogging)
		end
	end

	CurrentCharacter:Move()

	--
	Replicator:Move(Player)
end

function Service:PivotTo(Player: Player, Buffer: buffer, Force: boolean?)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)
	local X, Z = buffer.readf32(Buffer, 2), buffer.readf32(Buffer, 6)
	local Y = buffer.readi16(Buffer, 10) / 100
	local Vector = Vector3.new(X, Y, Z)

	CurrentCharacter:PivotTo(CFrame.lookAlong(Vector, CurrentCharacter:GetPivot().LookVector))

	Replicator:PivotTo(Player, Vector)
end

function Service:SnapTo(Player: Player, CF: CFrame)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)
	local Vector = CF.Position

	CurrentCharacter:PivotTo(CFrame.lookAlong(Vector, CurrentCharacter:GetPivot().LookVector))
	Replicator:PivotTo(Player, Vector, Player)
	Replicator:PivotTo(Player, Vector)
end

function Service:Stop(Player: Player)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)

	CurrentCharacter:Stop()

	--
	Replicator:Stop(Player)
end

function Service:Rotate(Player: Player, Buffer: buffer)
	local Angle = math.rad(buffer.readi16(Buffer, 1) / 180)
	local X, Z = math.sin(Angle), math.cos(Angle)
	local Rebuilt = Vector3.new(X, 0, Z)

	local CurrentCharacter = Service:GetCurrentCharacter(Player)
	CurrentCharacter:Rotate(Rebuilt)

	--
	Replicator:Rotate(Player, Rebuilt)
end

function Service:KeySwitch(Player: Player, bufferObj, Value: boolean)
	local Key = GameEnum.KeyLookup(GameEnum.Agent_Keys, buffer.readu8(bufferObj, 1))

	local Data = Service:Get(Player)
	local ReplicateMovement = false

	for _, Character in Data.Characters do
		Character:SetKey(Key, Value)

		if Character:IsMoving() then
			ReplicateMovement = true
		end
	end

	if ReplicateMovement then
		Service:Move(Player)
	end

	--
	Replicator:KeySwitch(Player, Key, Data.Characters[1]:GetKey(Key))
end

function Service:CharacterSwitch(Player: Player, Buffer: buffer)
	local AgentIndex, Direction = Math:Decodeu2u6(Buffer, 1)
	local IsNext = Direction == 1

	local Angle = math.rad(buffer.readi16(Buffer, 2) / 180)
	local X, Z = math.sin(Angle), math.cos(Angle)
	local RebuiltRotationVector = Vector3.new(X, 0, Z)

	local Data = Service:Get(Player)
	local Previous = Data.Characters[Data.Active]
	local New = Data.Characters[AgentIndex]

	if not New:IsAlive() then
		return
	end

	local WasMoving = Previous:IsMoving()

	--
	local MarkedAgentStruct = Previous:GetMarkedTarget()
	local Target = IsNext and MarkedAgentStruct ~= nil and Enemies:GetEnemy(MarkedAgentStruct.TargetId) or nil

	local CharacterCFrame = AssistUtil:CalculateSwitchCFrame(Previous, Direction, Target)

	Data.Active = AgentIndex

	--
	for _, Character in Service:GetCharacters(Player) do
		Character:SetActive(Character == New)
	end

	New:PivotTo(CharacterCFrame)
	New:Rotate(RebuiltRotationVector)

	if not Target then
		New:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, Statics.Dodge_Active_Time)
		New:ApplyImpulse(New:GetPivot().LookVector * Statics.Switch_Character_Dash_Strength)
	end

	if WasMoving then
		Service:Move(Player)
	end

	Replicator:CharacterSwitch(Player, AgentIndex, Direction, MarkedAgentStruct and MarkedAgentStruct.TargetId)
	Replicator:Rotate(Player, RebuiltRotationVector)

	--
	if MarkedAgentStruct then
		if IsNext then
			MarkedAgentStruct.Accepted:Fire()
		else
			MarkedAgentStruct.Accepted:DisconnectAll()
		end

		MarkedAgentStruct.TargetId = nil
	end
end

function Service:GetCurrentCharacter(Player: Player): AgentTypes.ServerCharacterClass?
	local Data = Service:Get(Player)

	return Data.Characters[Data.Active]
end

function Service:GetCharacters(Player: Player)
	local Data = Service:Get(Player)

	return Data.Characters
end

function Service:Sync(Player: Player, Target: Player)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)

	if not CurrentCharacter then
		return
	end

	Replicator:AddAgent(Player, CurrentCharacter, Target, CurrentCharacter:GetPivot())

	for _, Character in Service:GetCharacters(Player) do
		if Character ~= CurrentCharacter then
			Replicator:AddAgent(Player, Character, Target)
		end
	end

	Replicator:Rotate(Player, CurrentCharacter.__Character.__Rotation, Target)

	if CurrentCharacter:IsMoving() then
		Replicator:Move(Player, Target)
	end

	Replicator:SyncVelocities(Player, Target,
		CurrentCharacter.__Velocity,
		CurrentCharacter.__LastMovementVelocity,
		CurrentCharacter.__SurfaceVelocity,
		CurrentCharacter.__MovementVelocity
	)
end

return Service
