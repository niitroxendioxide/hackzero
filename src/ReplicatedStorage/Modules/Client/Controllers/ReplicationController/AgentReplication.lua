--
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Companion = require(Client.Classes.Companion)
local Companions = require(Client.Libraries.Companions)
local CompanionsDatabase = require(Shared.Database.Companions)
local Math = require(Shared.Utility.Math)
local CharacterLibrary = require(Client.Libraries.Characters)
local AgentClass = require(Client.Classes.Agent)
local GameEnum = require(Shared.GameEnum)
local AnimLib = require(Client.Libraries.Animation)

--local BufferUtil = require(Shared.Utility.Buffer)
local InterfaceStates = require(Client.Packages.InterfaceStates)
local CharacterDatabase = require(Shared.Database.Characters)
local SharedData = require(Client.Libraries.SharedData)
local LocalData = require(Client.Libraries.LocalData)

--
local AnimsLoaded = {}
local function GetPlayerById(Id: number)
	for _, Player in Players:GetChildren() do
		if Player:GetAttribute("ReplicationId") == Id then
			return Player
		end
	end

	return;
end

local function IsOwnId(Id: number)
	return Id == (Players.LocalPlayer:GetAttribute("ReplicationId") :: number)
end

local function LoadAllCharacterAnimations(Name: string)
	if AnimsLoaded[Name] then
		return
	end

	local CharacterAnims = ReplicatedStorage.Assets.Animations.Characters
	local GivenCharacterDir = CharacterAnims:FindFirstChild(Name)
	if not GivenCharacterDir then
		return
	end

	AnimsLoaded[Name] = true
	local AnimTable = {}

	for _, AnimationObject: Animation in GivenCharacterDir:GetDescendants() do
		if not AnimationObject:IsA('Animation') then
			continue
		end

		table.insert(AnimTable, AnimationObject)
	end

	ContentProvider:PreloadAsync(AnimTable, function(Id, Status): ...any
		if Status == Enum.AssetFetchStatus.Failure then
			Debugger:DebugLine("ContentProvider.PreloadAsync", "Failed to load animation with id:" .. Id, 5)
		end
	end)
end

--
local Controller = {}

function Controller:AddAgent(Buffer: buffer, At: CFrame)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local Level = buffer.readu8(Buffer, 3)
	local CharacterName = CharacterDatabase:GetCharacterFromId(CharacterId)

	if CharacterLibrary:HasCharacter(UserId, CharacterName) then
		warn('Cannot add same character twice for a player')

		return
	end

	if IsOwnId(UserId) then
		task.spawn(LoadAllCharacterAnimations, CharacterName)
	end

	local AgentOwner = GetPlayerById(UserId)
	local AgentData = SharedData:GetAgentData(AgentOwner, CharacterName) -- or {Level = 1, Name = CharacterName, Artifacts = {}, Drive = nil}
	if AgentData == nil and (IsOwnId(UserId)) then
		AgentData = LocalData:GetAgent(CharacterName)
	end

	if not AgentData then
		AgentData = {
			Artifacts = {},
			Level = Level or 60,
			Drive = nil,
		}
	end

	local CharacterInstance = AgentClass.new(CharacterName, AgentData.Level)
	

	--CharacterInstance.__Controller:GetCollider().Transparency = 0.9

	CharacterLibrary:Add(UserId, CharacterInstance)
	CharacterInstance:Stop()

	if At then
		CharacterInstance:PivotTo(At)
	end

	do
		CharacterInstance:SetLevel(AgentData.Level)

		for _, ArtifactId in (AgentData.Artifacts or {}) do
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

	CharacterInstance:Init(UserId)
	CharacterInstance.__Character.__Appearance.__Orientation.Responsiveness = 50

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
	local Angle = math.rad(buffer.readi16(Buffer, 1) / 180)
	local X, Z = math.sin(Angle), math.cos(Angle)
	local Rebuilt = Vector3.new(X, 0, Z)

	local UserId = buffer.readu8(Buffer, 3)
	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:Look(Rebuilt, true, true)
end

function Controller:PivotTo(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)
	local X, Z = buffer.readf32(Buffer, 2), buffer.readf32(Buffer, 6)
	local Y = buffer.readi16(Buffer, 10) / 100
	local Vector = Vector3.new(X, Y, Z)

	local Character = CharacterLibrary:GetCurrent(UserId)
	if not Character then
		return
	end

	if IsOwnId(UserId) then
		Character:MarkServerAction(GameEnum.Replication.PivotTo)
	end

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
	if not CurrentCharacter then
		return;
	end

	CurrentCharacter:SyncVelocities(LM, SV, MV, V)
end

function Controller:CharacterSwitch(Buffer: buffer)
	local Index = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local EnemyTargetId = buffer.readu8(Buffer, 3)

	local Previous = CharacterLibrary:GetCurrent(UserId)
	local Moving = Previous:IsMoving()

	CharacterLibrary:SwitchToIndex(UserId, Index, EnemyTargetId)

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

	Agent:MarkServerAction(GameEnum.Replication.UpdateEnergy);
	Agent:SetEnergy(Energy)

	InterfaceStates.Energy[AgentId]:set(Energy)
end

function Controller:UpdateUltBar(Buffer: buffer)
	local AgentId = buffer.readu8(Buffer, 1)
	local UltAmount = math.round(buffer.readu16(Buffer, 2) / 600)
	local Agent = CharacterLibrary:GetAgent(Players.LocalPlayer:GetAttribute("ReplicationId"), AgentId)

	Agent:MarkServerAction(GameEnum.Replication.UpdateUltBar);
	Agent:SetUltBar(UltAmount)

	InterfaceStates.UltBar[AgentId]:set(UltAmount)
end

function Controller:CreateCompanion(Buffer: buffer, UUID: string)
	local Id = buffer.readu8(Buffer, 1)
	local OwnerId = buffer.readu8(Buffer, 2)
	local CompanionNameId = buffer.readu8(Buffer, 3)
	local At = Math:DecodeCFrame(Buffer, 4)
	
	local CompanionName = CompanionsDatabase:GetFromId(CompanionNameId)

	local CompanionClass = Companion.new(CompanionName, At, UUID)
	CompanionClass:Init(Id, OwnerId)
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

function Controller:AddTag(Buffer: buffer, Tag: string)
	local PlayerId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local Time = buffer.readu16(Buffer, 3) / 100
	if Time <= 0 then
		Time = 5e12
	end

	local AgentObj = CharacterLibrary:GetAgent(PlayerId, AgentId)
	if not AgentObj then
		return
	end

	AgentObj:AddTag(Tag, Time)
end


function Controller:RemoveTag(Buffer: buffer, Tag: string)
	local PlayerId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)

	local AgentObj = CharacterLibrary:GetAgent(PlayerId, AgentId)
	if not AgentObj then
		return
	end

	AgentObj:RemoveTag(Tag)
end


return Controller
