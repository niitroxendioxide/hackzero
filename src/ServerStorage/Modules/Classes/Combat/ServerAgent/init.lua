--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

--
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local CharacterDatabase = require(Shared.Database.Characters)
local CharacterClass = require(Classes.Combat.ServerAgent.ServerCharacter)
local AgentStatus = require(Shared.Classes.Agents.Status)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local ServerAgentClass = {}
ServerAgentClass.__index = ServerAgentClass
ServerAgentClass.__tostring = function()
	return 'AgentClass'
end


function ServerAgentClass.new(Name: string, Level: number): Types.AgentClass
	local self = setmetatable({}, ServerAgentClass)
	
	self.Name = Name
	
	--
	local Appearance = CharacterDatabase:GetAppearanceData(Name)
	

	self.__Tags = {}
	self.__Level = Level
	self.__User = -125
	self.__Active = false
	self.__Character = CharacterClass.new(Name, Appearance.Height)
	
	self.__Status = AgentStatus.new(CharacterDatabase:GetStatsAtLevel(Name, Level))
	
	
	return self
end

function ServerAgentClass:GetId(): number
	return self.__User
end

function ServerAgentClass:GetHitbox()
	return self.__Character.__Collider
end

function ServerAgentClass:GetTotalVelocity()
	return self.__Character:GetTotalVelocity()
end

function ServerAgentClass:GetEnergy()
	return self.__Status:GetEnergy()
end

function ServerAgentClass:GetStat(Name: Types.Stat): number
	return self.__Status:GetStat(Name)
end

function ServerAgentClass:GetMultBonus(Name: string)
	return self.__Status:GetMultBonus(Name)
end

function ServerAgentClass:Init(Key: number)
	assert(typeof(Key) == 'number', 'Cannot initialize character with nil key')
	
	self.__User = Key
	
	self.__Main_Thread = RunService.Heartbeat:Connect(function(Delta: number)
		self.__Status:Update(Delta)
	end)

	
	return self.__Character:Init()
end

function ServerAgentClass:SetActive(State: boolean)
	self.__Active = State
end

function ServerAgentClass:IsMoving()
	return self.__Character:IsMoving()
end

function ServerAgentClass:Move()
	return self.__Character:Move()
end

function ServerAgentClass:Stop()
	return self.__Character:Stop()
end

function ServerAgentClass:Rotate(...)
	return self.__Character:Rotate(...)
end

function ServerAgentClass:Look(...)
	return self:Rotate(...)
end

function ServerAgentClass:Walk(Time: number)
	local Speed = self.__Character.States:GetSpeed(true)
	local Direction = self:GetPivot().LookVector * Speed
	
	return self.__Character:AddLinearMovement(Direction, Time)
end

function ServerAgentClass:GetPivot(...)
	return self.__Character:GetPivot(...)
end

function ServerAgentClass:PivotTo(...)
	return self.__Character:PivotTo(...)
end

function ServerAgentClass:SetKey(...)
	return self.__Character.States:SetKey(...)
end

function ServerAgentClass:GetKey(...)
	return self.__Character.States:GetKey(...)
end

function ServerAgentClass:ApplyImpulse(Velocity: Vector3)
	return  self.__Character:ApplyImpulse(Velocity)
end

function ServerAgentClass:GetState()
	return self.__Character:GetState()
end

function ServerAgentClass:SwitchState(State: string, Time: number)
	self.__Character.States:Switch(State, Time)

	if self:IsMoving() then
		self:Move()
	end
end

-- # Interacting
function ServerAgentClass:TakeDamage(Amount: number)
	Replicator:DamageAgent(self, Amount)
	
	return self.__Status:Damage(Amount)
end

function ServerAgentClass:Heal(...)
	return self.__Status:Heal(...)
end

function ServerAgentClass:GetHealth(): (number, number)
	return self.__Status:GetHealth()
end


function ServerAgentClass:AddTag(Tag: string, Time: number)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil
	end)
end

function ServerAgentClass:RemoveTag(Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = nil
end

function ServerAgentClass:HasTag(Tag: string)
	return self.__Tags[Tag] ~= nil
end


return ServerAgentClass
