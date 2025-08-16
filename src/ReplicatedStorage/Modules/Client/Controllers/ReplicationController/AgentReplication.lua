--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Companion = require(ReplicatedStorage.Modules.Client.Classes.Companion)
local Companions = require(ReplicatedStorage.Modules.Client.Libraries.Companions)
local Math = require(Shared.Utility.Math)
local CharacterLibrary = require(Client.Libraries.Characters)
local AgentClass = require(Client.Classes.Agent)
local GameEnum = require(Shared.GameEnum)

--local BufferUtil = require(Shared.Utility.Buffer)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local CharacterDatabase = require(Shared.Database.Characters)
local SharedData = require(Client.Libraries.SharedData)

--
local function GetPlayerById(Id: number)
	for _, Player in Players:GetChildren() do
		if Player:GetAttribute("ReplicationId") == Id then
			return Player
		end
	end

	return;
end

--
local Controller = {}

function Controller:AddAgent(Buffer: buffer, At: CFrame)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local CharacterName = CharacterDatabase:GetCharacterFromId(CharacterId)

	if CharacterLibrary:HasCharacter(UserId, CharacterName) then
		warn('Cannot add same character twice for a player')

		return
	end

	local AgentOwner = GetPlayerById(UserId)
	local AgentData = SharedData:GetAgentData(AgentOwner, CharacterName)-- or {Level = 1, Name = CharacterName, Artifacts = {}, Drive = nil}

	local CharacterInstance = AgentClass.new(CharacterName, AgentData.Level)
	CharacterInstance:Init(UserId)

	--CharacterInstance.__Controller:GetCollider().Transparency = 0.9

	CharacterInstance.__Character.__Appearance.__Orientation.Responsiveness = 50
	CharacterLibrary:Add(UserId, CharacterInstance)
	CharacterInstance:Stop()

	if At then
		CharacterInstance:PivotTo(At)
	end

	do
		CharacterInstance:SetLevel(AgentData.Level)

		for _, ArtifactId in AgentData.Artifacts do
			local ArtifactData = SharedData:GetArtifactById(AgentOwner, ArtifactId)

			if ArtifactData ~= nil then
				CharacterInstance.__Items:BindArtifact(ArtifactData)
			end
		end

		if AgentData.Drive ~= nil then
			local DriveObj = SharedData:GetDriveById(AgentOwner, AgentData.Drive)
			CharacterInstance.__Items:BindDrive(DriveObj)
		end
	end

	if CharacterLibrary:GetCurrent(UserId) ~= CharacterInstance then
		CharacterInstance:SetVisible(false)
	end
end

function Controller:RemoveAgent(Buffer: buffer)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local Character = CharacterDatabase:GetCharacterFromId(CharacterId)

	local CharInsance = CharacterLibrary:Remove(UserId, Character)

	if CharInsance then
		CharInsance:Destroy()
	end
end

function Controller:Rotate(Buffer: buffer)
	local Angle = math.rad(buffer.readi16(Buffer, 1) / 5133)
	local X, Z = math.sin(Angle), math.cos(Angle)
	local Rebuilt = Vector3.new(X, 0, Z)

	local UserId = buffer.readu8(Buffer, 3)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:Look(Rebuilt, true)
end

function Controller:PivotTo(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)
	local X, Z = buffer.readf32(Buffer, 2), buffer.readf32(Buffer, 6)
	local Y = buffer.readi16(Buffer, 10) / 100
	local Vector = Vector3.new(X, Y, Z)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:PivotTo(CFrame.lookAlong(Vector, Character.__Character.__Controller.__Rotation), true)
end

function Controller:KeySwitch(Buffer: buffer, Value: boolean)
	local Key = GameEnum.KeyLookup(GameEnum.Agent_Keys, buffer.readu8(Buffer, 1))
	local UserId = buffer.readu8(Buffer, 2)

	local Characters = CharacterLibrary:GetCharacters(UserId)

	for _, Character in Characters do
		Character:SetKey(Key, Value)

		if Character:IsMoving() then
			Character:Move()
		else
			Character:Stop()
		end
	end
end

function Controller:Move(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:Move()
end

function Controller:Stop(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)

	for _, Character in CharacterLibrary:GetCharacters(UserId) do
		Character:Stop()
	end
end

function Controller:ClearPlayerData(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)

	CharacterLibrary:RemoveAll(Id)
end

function Controller:SyncVelocities(Buffer: buffer, V, LM, SV, MV)
	local UserId = buffer.readu8(Buffer, 1)

	local CurrentCharacter = CharacterLibrary:GetCurrent(UserId)
	CurrentCharacter.__Controller.__Velocity = LM
	CurrentCharacter.__Controller.__SurfaceVelocity = SV
	CurrentCharacter.__Controller.__MovementVelocity = MV
	CurrentCharacter.__Controller.__LastMovementVelocity = V
end

function Controller:CharacterSwitch(Buffer: buffer)
	local Index, Direction = Math:Decodeu2u6(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local EnemyTargetId = buffer.readu8(Buffer, 3)

	local Previous = CharacterLibrary:GetCurrent(UserId)
	local Moving = Previous:IsMoving()

	--local CFrameClient = Previous:GetPivot()

	CharacterLibrary:SwitchToIndex(UserId, Index, Direction, EnemyTargetId)

	if Moving then
		local Current = CharacterLibrary:GetCurrent(UserId)

		Current:Look(Previous:GetRotation())
		Current:Move()
	end
end

function Controller:UpdateEnergy(Buffer: buffer)
	local Energy = math.round(buffer.readu16(Buffer, 2) / 600)
	local AgentId = buffer.readu8(Buffer, 1)
	local Agent = CharacterLibrary:GetAgent(Players.LocalPlayer:GetAttribute("ReplicationId"), AgentId)

	Agent:SetEnergy(Energy)
	InterfaceStates.Energy[AgentId]:set(Energy)
end

function Controller:UpdateUltBar(Buffer: buffer)
	local AgentId = buffer.readu8(Buffer, 1)
	local UltAmount = math.round(buffer.readu16(Buffer, 2) / 600)
	local Agent = CharacterLibrary:GetAgent(Players.LocalPlayer:GetAttribute("ReplicationId"), AgentId)

	Agent:SetUltBar(UltAmount)
	InterfaceStates.UltBar[AgentId]:set(UltAmount)
end

function Controller:CreateCompanion(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)
	local At = Math:DecodeCFrame(Buffer, 2)
	local CompanionClass = Companion.new("Template", At)
	CompanionClass:Init(Id)

	Companions:Add(CompanionClass, Id)
end

function Controller:MoveCompanion(Buffer: buffer)
	local CompanionId = buffer.readu8(Buffer, 1)
	local At = Math:DecodeCFrame(Buffer, 2)

	local Class = Companions:Get(CompanionId)
	if not Class then
		return
	end

	Class:Move(At)
end

function Controller:SetMovingStatusCompanion(Buffer: buffer)
	local CompanionId = buffer.readu8(Buffer, 1)
	local State = buffer.readu8(Buffer, 2) == 1

	local Class = Companions:Get(CompanionId)
	if not Class then
		return
	end

	Class:SetMoving(State)
end


return Controller
