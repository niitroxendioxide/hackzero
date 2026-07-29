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

	local CanMove = CurrentCharacter:GetState() ~= 'Attacking'
	if CanMove then
		CurrentCharacter:Move()
		Replicator:Move(Player)
	else
		CurrentCharacter:Stop()
		Replicator:Stop(Player)
	end

	--
end

function Service:PivotTo(Player: Player, Buffer: buffer, Force: boolean?)
	local CurrentCharacter = Service:GetCurrentCharacter(Player)
	local X, Z = buffer.readf32(Buffer, 2), buffer.readf32(Buffer, 6)
	local Y = buffer.readi16(Buffer, 10) / 100
	local Vector = Vector3.new(X, Y, Z)
	local CharacterNewCFrame = CFrame.lookAlong(Vector, CurrentCharacter:GetPivot().LookVector)

	CurrentCharacter:PivotTo(CharacterNewCFrame, true);

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
	local Angle = buffer.readi16(Buffer, 1) / 5133
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

function Service:CharacterSwitch(Player: Player, Buffer: buffer, p_Target: number, p_ForceRotate: boolean)
	local Data = Service:Get(Player)
	local NewAgentIndex = buffer.readu8(Buffer, 1)
	local PrevIndex = Data.Active
	
	local PreviousAgent = Data.Characters[PrevIndex]
	local NewAgent = Data.Characters[NewAgentIndex]

	if not NewAgent:IsAlive() then
		return
	end

	--- rotation vector math
	local Angle = math.rad(buffer.readi16(Buffer, 2) / 180)
	local rX, rZ = math.sin(Angle), math.cos(Angle)
	local RebuiltRotationVector = vector.create(rX, 0, rZ)

	--- switching & other
	Data.Active = NewAgentIndex

	local WasMoving = PreviousAgent:IsMoving()
	local MarkedAgentStruct = PreviousAgent:GetMarkedTarget()
	local Target = p_Target
	if MarkedAgentStruct ~= nil then
		Target = Enemies:GetEnemy(MarkedAgentStruct.TargetId)
	end

	local SwitchCFrame = AssistUtil:CalculateSwitchCFrame(PreviousAgent, 1, Target, p_ForceRotate)
	for _, PlayerAgent in Service:GetCharacters(Player) do
		PlayerAgent:SetActive(PlayerAgent == NewAgent)
	end

	if not NewAgent:HasTag("CharacterStatic") then
		NewAgent:PivotTo(SwitchCFrame)
		NewAgent:Rotate(RebuiltRotationVector)

		if not Target then
			NewAgent:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, Statics.Dodge_Active_Time)
			NewAgent:ImpulseForward(Statics.Switch_Character_Dash_Strength, 0.75)
		end

		if WasMoving then
			Service:Move(Player)
		end
	end

	Replicator:CharacterSwitch(Player, NewAgentIndex, 1, Target and Target:GetId())
	Replicator:Rotate(Player, RebuiltRotationVector)

	---
	if MarkedAgentStruct then
		--print('Id: ', MarkedAgentStruct.AssistCharacterId, "New IndeX:", NewAgentIndex)

		if MarkedAgentStruct.AssistCharacterId == NewAgentIndex then
			MarkedAgentStruct.Accepted:Fire()
		end

		MarkedAgentStruct.Accepted:DisconnectAll()

		MarkedAgentStruct.TargetId = nil
	end
end

function Service:oldswitch(Player: Player, Buffer: buffer, ParameterTarget: number, ForceRotateVector: boolean)
	local AgentIndex, Direction = Math:Decodeu2u6(Buffer, 1)
	local IsNext = Direction == 1

	if Direction ~= 1 then
		Direction = -1
	end

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
	local Target = if IsNext and MarkedAgentStruct ~= nil then Enemies:GetEnemy(MarkedAgentStruct.TargetId) elseif ParameterTarget ~= nil then ParameterTarget else nil

	local CharacterCFrame = AssistUtil:CalculateSwitchCFrame(Previous, Direction, Target, ForceRotateVector)

	Data.Active = AgentIndex

	--
	for _, Character in Service:GetCharacters(Player) do
		Character:SetActive(Character == New)
	end

	if not New:HasTag("CharacterStatic") then
		New:PivotTo(CharacterCFrame)
		New:Rotate(RebuiltRotationVector)

		if not Target then
			New:AddTag(GameEnum.Boost_Effects.DODGE_FLOW_TRIGGER, Statics.Dodge_Active_Time)
			New:ImpulseForward(Statics.Switch_Character_Dash_Strength, 0.75)
		end

		if WasMoving then
			Service:Move(Player)
		end

		Replicator:CharacterSwitch(Player, AgentIndex, Direction, Target and Target:GetId())
		Replicator:Rotate(Player, RebuiltRotationVector)
	end

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
