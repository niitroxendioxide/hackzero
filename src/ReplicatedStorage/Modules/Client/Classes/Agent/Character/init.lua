--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Characters = require(ReplicatedStorage.Modules.Shared.Database.Characters)
local Types = require(Shared.Types)

--
local Appearance = require(Client.Classes:WaitForChild('Appearance'))
local Animator = require(script:WaitForChild('Animator'))
local Physics = require(script:WaitForChild('Physics'))
local States = require(Shared.Classes.Agents.States)

--
local CharacterClass = {} :: {[string]: (self: Types.CharacterClass, any) -> (), new: (Design: string) -> Types.CharacterClass}
CharacterClass.__index = CharacterClass

function CharacterClass.new(Character: string)
	local CharacterData = Characters:GetCharacterData(Character, true)
	local self = setmetatable({}, {__index = function(self, key)
		if key == 'Collider' then
			return (rawget(self, '__Controller') :: any):GetCollider()
		elseif key == 'Humanoid' then
			return (rawget(self, '__Appearance') :: any).__Model:FindFirstChild('Humanoid')
		end

		return CharacterClass[key]
	end,})


	local ModelName, Directory = Character, nil;
	if CharacterData.Model ~= nil then
		local Split = string.split(CharacterData.Model, "/");

		Directory = Split[1]
		ModelName = Split[2]
	end

	self.__Tags = {}
	self.__Appearance = Appearance.new(ModelName, Directory)
	self.__States = States.new(Character)
	self.__Controller = Physics.new(self.__States, CharacterData.Appearance.Height, Character == 'Goku' and true)
	self.__Animator = Animator.new(self, Character)

	self.Name = Character

	return self
end

function CharacterClass:AddTag(Tag: string)
	if not table.find(self.__Tags, Tag) then
		table.insert(self.__Tags, Tag)
	end
end

function CharacterClass:SetPhysicsEnabled(State: boolean)
	if State then
		self.__Controller:Resume()
	else
		self.__Controller:Pause()
	end
end

function CharacterClass:RemoveTag(Tag: string)
	if table.find(self.__Tags, Tag) then
		table.remove(self.__Tags, table.find(self.__Tags, Tag))
	end
end

function CharacterClass:Init()
	self.__Controller:Run()

	self.__Appearance:JoinTo(self.__Controller:GetCollider())

	self.__Animator:Init()
end

function CharacterClass:GetState()
	return self.__States:GetState()
end

function CharacterClass:Move()
	local Speed = self:GetMovementSpeed(nil, true)

	return self.__Controller:SetMovementVelocity(Speed)
end

function CharacterClass:Stop()
	return self.__Controller:StopMovement()
end

function CharacterClass:GetMovementSpeed(...)
	return self.__States:GetSpeed(...)
end

function CharacterClass:SetKey(Key: string, State: boolean)
	self.__States:SetKey(Key, State)
end

function CharacterClass:GetKey(Key: string): boolean
	return self.__States:GetKey(Key)
end

function CharacterClass:GetPivot(): CFrame
	return self.__Controller:GetPivot()
end

function CharacterClass:PivotTo(At: CFrame, IgnoreModel: boolean?): ()
	if not IgnoreModel then
		self.__Appearance.__Model:PivotTo(At)
	end

	return self.__Controller:PivotTo(At)
end

function CharacterClass:CorrectTo(At: CFrame): boolean
	return self.__Controller:CorrectTo(At)
end

function CharacterClass:Look(Direction: Vector3, ...)
	if Direction.Magnitude <= 0 then
		return
	end

	return self.__Controller:Rotate(Direction, ...)
end

function CharacterClass:SetVisible(State: boolean?)
	State = if State == nil then not self.__Appearance.__Visible else State

	return self.__Appearance:SetVisible(State)
end

function CharacterClass:GetModel(): ()
	return self.__Appearance.__Model
end

function CharacterClass:IsMoving(): ()
	return self.__Controller.__Moving
end

function CharacterClass:Destroy()
	self.__States:Destroy()
	self.__Animator:Destroy()
	self.__Controller:Destroy()
	self.__Appearance:Destroy()
end

function CharacterClass:AddEffect(...)
	return self.__States:AddEffect(...)
end

function CharacterClass:GetEffect(...)
	return self.__States:GetEffect(...)
end

return CharacterClass
