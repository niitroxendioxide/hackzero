--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
--local Enemies = require(Shared.Libraries.Enemies)
local CharacterClass = require(script:WaitForChild('Character'))
local StatusClass = require(Shared.Classes.Agents:WaitForChild('Status'))

--local InterfaceStates = require(Client.Packages.InterfaceStates)
local CharacterDatabase = require(Shared.Database.Characters)

--
local AgentClass = {} :: {[string]: (self: Types.AgentClass, any) -> any, new: (Name: string, Level: number) -> Types.AgentClass}
AgentClass.__index = AgentClass
AgentClass.__tostring = function()
	return 'AgentClass'
end

function AgentClass.new(Name: string, Level: number): Types.AgentClass
	local self = setmetatable({}, AgentClass)

	self.Name = Name
	self.PlayerId = -125

	-- # Private
	self.__Tags = {}
	self.__Look_Marked = false
	self.__Character = CharacterClass.new(Name)
	self:SetLevel(Level)

	return self
end

function AgentClass:GetId(): number
	return self.PlayerId
end

function AgentClass:SetLevel(Amount: number)
	self.__Level = Amount
	self.__Status = StatusClass.new(CharacterDatabase:GetStatsAtLevel(self.Name, self.__Level))
end

function AgentClass:GetStat(Key: string)
	return self.__Status:GetStat(Key)
end

function AgentClass:GetAnimator(): Types.AnimatorController
	return self.__Character.__Animator
end

function AgentClass:GetHitbox(): BasePart
	return self.__Character.__Controller:GetCollider()
end

function AgentClass:AddTrackToState(...)
	return self:GetAnimator():AddTrackToState(...)
end

function AgentClass:Move()
	return self.__Character:Move()
end

function AgentClass:Stop()
	return self.__Character:Stop()
end

function AgentClass:GetEnergy()
	return self.__Status:GetEnergy()
end

function AgentClass:SetEnergy(Amount: number)
	self.__Status:SetEnergy(Amount)
end

function AgentClass:BlockRotation(Time: number)
	if self.__Look_Marked_Thread then
		task.cancel(self.__Look_Marked_Thread)
	end

	self.__Look_Marked = true
	self.__Look_Marked_Thread = task.delay(Time, function()
		self.__Look_Marked = false
	end)
end

function AgentClass:Look(Vector, Instant, Bypass)
	if not Bypass and (self:GetState() ~= 'Idle' or (self.__Character.__States:GetLastChangeTime() < .1) and self:GetState() ~= 'Dashing') then
		return
	end

	if self.__Look_Marked then
		return
	end

	return self.__Character:Look(Vector, Instant)
end

function AgentClass:SetVisible(...)
	return self.__Character:SetVisible(...)
end

function AgentClass:Init(PlayerId: number)
	assert(typeof(PlayerId) == 'number', 'Requires a valid playerid to initialize agent.')
	
	self.PlayerId = PlayerId
	
	self.__Main_Thread = RunService.Heartbeat:Connect(function(Delta: number)
		self.__Status:Update(Delta)
	end)
	
	return self.__Character:Init()
end

function AgentClass:GetRotation()
	return self.__Character.__Controller.__Rotation
end

function AgentClass:GetPivot(Server: boolean)
	if Server and self.__ServerLocation then
		return self.__ServerLocation
	end
	
	return self.__Character:GetPivot()
end

function AgentClass:GetKey(...)
	return self.__Character:GetKey(...)
end

function AgentClass:SetKey(...)
	return self.__Character:SetKey(...)
end

function AgentClass:GetModel()
	return self.__Character:GetModel()
end

function AgentClass:IsMoving()
	return self.__Character:IsMoving()
end

function AgentClass:Walk(Time: number)
	local Speed = self.__Character.__States:GetSpeed(true)
	local Direction = self:GetPivot().LookVector * Speed
	
	return self.__Character.__Controller:AddLinearMovement(Direction, Time)
end

function AgentClass:PivotTo(...)
	return self.__Character:PivotTo(...)
end

function AgentClass:ApplyImpulse(...)
	return self.__Character.__Controller:ApplyImpulse(...)
end

function AgentClass:AddEffect(...)
	return self.__Character:AddEffect(...)
end

function AgentClass:GetEffect(...)
	return self.__Character:GetEffect(...)
end

function AgentClass:GetState()
	return self.__Character:GetState()
end

function AgentClass:SwitchState(State: string, Time: number)
	self.__Character.__States:Switch(State, Time)
	
	if self:IsMoving() then
		self:Move()
	end
end

-- # Gameplay Core
function AgentClass:IsDead()
	return self.__Status.Health > 0
end

function AgentClass:TakeDamage(...)
	return self.__Status:Damage(...)
end

function AgentClass:Heal(...)
	return self.__Status:Heal(...)
end

function AgentClass:GetHealth(): (number, number)
	return self.__Status:GetHealth()
end

function AgentClass:AddTag(Tag: string, Time: number)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end
	
	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil
	end)
end

function AgentClass:RemoveTag(Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = nil
end

function AgentClass:HasTag(Tag: string)
	return self.__Tags[Tag] ~= nil
end

return AgentClass
