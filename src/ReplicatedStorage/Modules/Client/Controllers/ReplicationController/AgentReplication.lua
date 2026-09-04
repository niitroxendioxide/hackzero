--
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Statics = require(Shared.Database.Statics)
local Companion = require(Client.Classes.Companion)
local Companions = require(Client.Libraries.Companions)
local CompanionsDatabase = require(Shared.Database.Companions)
local Math = require(Shared.Utility.Math)
local CharacterLibrary = require(Client.Libraries.Characters)
local AgentClass = require(Client.Classes.Agent)
local GameEnum = require(Shared.GameEnum)

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

function Controller:AddAgent(Buffer: buffer, At: CFrame, OverrideArtifacts: {}?)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local Level = buffer.readu8(Buffer, 3)
	local CharacterName = CharacterDatabase:GetCharacterFromId(CharacterId)

	if typeof(OverrideArtifacts) == 'table' and #OverrideArtifacts <= 0 then
		OverrideArtifacts = nil
	end

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

		for _, ArtifactId in (OverrideArtifacts or AgentData.Artifacts or {}) do
			local ArtifactData = SharedData:GetArtifactById(AgentOwner, ArtifactId)
			if not ArtifactData and RunService:IsStudio() then
				ArtifactData = LocalData:GetArtifactById(ArtifactId)
			end

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
	local UserId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local Angle = math.rad(buffer.readi16(Buffer, 3) / 180)
	local X, Z = math.sin(Angle), math.cos(Angle)

	local Character = CharacterLibrary:GetAgent(UserId, AgentId)
	if not Character then
		return
	end

	-- Not instant: remote headings ease in via the rotation lerp in Physics
	-- rather than snapping. Bypass still set so an attacking agent still turns.
	Character:Look(Vector3.new(X, 0, Z), false, true)
end

function Controller:PivotTo(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)
	local AgentId = buffer.readu8(Buffer, 2)
	local At = Math:DecodeCFrame(Buffer, 3)
	local Ping = buffer.readu16(Buffer, 15) / 1000

	local Character = CharacterLibrary:GetAgent(UserId, AgentId)
	if not Character then
		return
	end 

	if IsOwnId(UserId) then
		Character:MarkServerAction(GameEnum.Replication.PivotTo)
	end

	--[[
		The packet describes where the sender was a round trip ago, so aim the
		correction at where they are now.

		The velocity used is our own local simulation of this agent, not the
		sender's -- the packet carries no velocity, and the local sim already
		knows the movement state because Move/Stop/Rotate arrive reliably. That
		works while the sim is confident, but it cuts both ways: a wrong local
		velocity makes extrapolation worse than none at all. So it is skipped
		while a dash or knockback impulse is decaying, which is exactly when the
		velocity is large, changing fast, and most likely to differ between the
		two machines.

		Ping is clamped so a spike cannot fling the agent across the map.
	]]
	local Controller_ = Character.__Character.__Controller
	local Target = At.Position

	if not Controller_:HasActiveImpulse() then
		Target += Controller_:GetTotalVelocity() * math.clamp(Ping, 0, Statics.Replication_Max_Extrapolation)
	end

	Character:CorrectTo(CFrame.lookAlong(Target, At.LookVector))
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

--[[
	Move and Stop are the same packet with the Moving bit flipped: the movement
	byte says which agent it is about and what its speed keys are, so a packet
	that crosses a character switch still lands on the agent the sender meant.
]]
local function ApplyMovementByte(Buffer: buffer)
	local UserId = buffer.readu8(Buffer, 1)
	local AgentId, Moving, Sprint, Jog = Math:DecodeMovementByte(buffer.readu8(Buffer, 2))

	local Character = CharacterLibrary:GetAgent(UserId, AgentId)
	if not Character then
		return
	end

	Character:SetKey('Sprint', Sprint)
	Character:SetKey('Jog', Jog)

	if Moving then
		Character:Move()
	else
		Character:Stop()
	end
end

function Controller:Move(Buffer: buffer)
	ApplyMovementByte(Buffer)
end

function Controller:Stop(Buffer: buffer)
	ApplyMovementByte(Buffer)
end

function Controller:ClearPlayerData(Buffer: buffer)
	local Id = buffer.readu8(Buffer, 1)

	CharacterLibrary:RemoveAll(Id)
end

function Controller:SyncVelocities(Buffer: buffer, Velocity, LastMovementVelocity, SurfaceVelocity)
	local UserId = buffer.readu8(Buffer, 1)

	local CurrentCharacter = CharacterLibrary:GetCurrent(UserId)
	if not CurrentCharacter then
		return;
	end

	CurrentCharacter:SyncVelocities(Velocity, LastMovementVelocity, SurfaceVelocity)
end

--[[
	The server resolves the switch destination and ships it in the packet, so a
	receiving client never has to reproduce the server's random draws.

	The owner gets this broadcast too: for them it is a correction against what
	they already predicted, and CorrectTo discards it when the prediction was
	right (the normal case now that the seed travels with the request).
]]
function Controller:CharacterSwitch(Buffer: buffer)
	local Index = buffer.readu8(Buffer, 1)
	local UserId = buffer.readu8(Buffer, 2)
	local EnemyTargetId = buffer.readu8(Buffer, 3)
	local At = Math:DecodeCFrame(Buffer, 4)

	local Previous = CharacterLibrary:GetCurrent(UserId)
	if not Previous then
		return
	end

	local Moving = Previous:IsMoving()

	if IsOwnId(UserId) then
		local Current = CharacterLibrary:GetAgent(UserId, Index)

		-- Already switched locally; only reconcile the position.
		if Current and CharacterLibrary:GetCurrent(UserId) == Current then
			Current:CorrectTo(At)

			return
		end
	end

	CharacterLibrary:SwitchToIndex(UserId, Index, At, EnemyTargetId > 0)

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
