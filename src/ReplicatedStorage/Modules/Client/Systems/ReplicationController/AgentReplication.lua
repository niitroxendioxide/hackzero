--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local CharacterLibrary = require(Client.Libraries.Characters)
local AgentClass = require(Client.Classes.Agent)
local GameEnum = require(Shared.GameEnum)

local BufferUtil = require(Shared.Utility.Buffer)
local CharacterDatabase = require(Shared.Database.Characters)
local InterfaceStates = require(Client.Packages.InterfaceStates)

local LocalUserId = Players.LocalPlayer.UserId

--
local Controller = {}

function Controller:AddAgent(Buffer: buffer, At: CFrame)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readi32(Buffer, 2)
	local CharacterName = CharacterDatabase:GetCharacterFromId(CharacterId)

	if CharacterLibrary:HasCharacter(UserId, CharacterName) then
		warn('Cannot add same character twice for a player')

		return
	end

	local CharacterInstance = AgentClass.new(CharacterName, 1)
	CharacterInstance:Init(UserId)

	--CharacterInstance.__Controller:GetCollider().Transparency = 0.9

	CharacterInstance.__Character.__Appearance.__Orientation.Responsiveness = 50
	CharacterLibrary:Add(UserId, CharacterInstance)
	CharacterInstance:Stop()

	if At then
		CharacterInstance:PivotTo(At)
	end

	if CharacterLibrary:GetCurrent(UserId) ~= CharacterInstance then
		CharacterInstance:SetVisible(false)
	end
end

function Controller:RemoveAgent(Buffer: buffer)
	local CharacterId = buffer.readu8(Buffer, 1)
	local UserId = buffer.readi32(Buffer, 2)
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
	
	local UserId = buffer.readi32(Buffer, 3)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:Look(Rebuilt, true)
end

function Controller:PivotTo(Buffer: buffer)
	local UserId = buffer.readi32(Buffer, 1)
	local X, Z = buffer.readf32(Buffer, 5), buffer.readf32(Buffer, 9)
	local Y = buffer.readi16(Buffer, 13) / 100
	local Vector = Vector3.new(X, Y, Z)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:PivotTo(CFrame.lookAlong(Vector, Character.__Character.__Controller.__Rotation), true)
end

function Controller:KeySwitch(Buffer: buffer, Key: string, Value: boolean)
	local Key = GameEnum.KeyLookup(GameEnum.Agent_Keys, buffer.readu8(Buffer, 1))
	local UserId = buffer.readi32(Buffer, 2)

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
	local UserId = buffer.readi32(Buffer, 1)

	local Character = CharacterLibrary:GetCurrent(UserId)

	Character:Move()
end

function Controller:Stop(Buffer: buffer)
	local UserId = buffer.readi32(Buffer, 1)

	for id, Character in CharacterLibrary:GetCharacters(UserId) do
		Character:Stop()
	end
end

function Controller:SyncVelocities(Buffer: buffer, V, LM, SV, MV)
	local UserId = buffer.readi32(Buffer, 1)

	local CurrentCharacter = CharacterLibrary:GetCurrent(UserId)
	CurrentCharacter.__Controller.__Velocity = LM
	CurrentCharacter.__Controller.__SurfaceVelocity = SV
	CurrentCharacter.__Controller.__MovementVelocity = MV
	CurrentCharacter.__Controller.__LastMovementVelocity = V
end

function Controller:CharacterSwitch(Buffer: buffer)
	local UserId = buffer.readi32(Buffer, 2)
	local Direction = buffer.readi8(Buffer, 1)

	local Previous = CharacterLibrary:GetCurrent(UserId)	
	local Moving = Previous:IsMoving()
	
	local CFrameClient = Previous:GetPivot()

	CharacterLibrary:Switch(UserId, Direction)

	if Moving then
		local Current = CharacterLibrary:GetCurrent(UserId)

		Current:Look(Previous:GetRotation())
		Current:Move()
	end
end

return Controller
