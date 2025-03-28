--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AnimLibrary = require(Client.Libraries.Animation)

--
local Priorities = {Idle = Enum.AnimationPriority.Core}
local AnimatorClass = {} :: {[string]: (self: Types.AnimatorController, any) -> any, new: (Enemy: Types.EnemyClass, Directory: string) -> Types.AnimatorController}
AnimatorClass.__index = AnimatorClass

function AnimatorClass.new(Enemy: Types.EnemyClass, Directory: string): Types.AnimatorController
	local self = setmetatable({}, AnimatorClass)
	self.__Tracks = {}
	self.__Directory = Directory
	self.__IsMoving = false
	self.__Character = Enemy
	self.__Angle = 0
	self.__SinceStop = os.clock()
	
	return self
end

function AnimatorClass:Init()
	if self.__Thread then
		return
	end
	
	self:Play('Idle')
	self:Play('Walk', {Weight = 0.001, Speed = 0.7})
	self:Play('WalkLeft', {Weight = 0.001, Speed = 0.6})
	self:Play('WalkRight', {Weight = 0.001, Speed = 0.6})
	
	self.__Thread = RunService.PostSimulation:Connect(function(delta: number)
		self:Update(delta)
	end)
end

function AnimatorClass:Play(Track: string, Data: {Fade: number, Speed: number, Weight: number})
	Data = Data or {}
	
	local RemovedId = tonumber(Track:sub(#Track, #Track)) ~= nil and Track:sub(1, #Track - 1) or Track
	local TrackObject = AnimLibrary:GetMovementAnim(self.__Directory, Track)
	local AnimTrack = AnimLibrary:Play(self.__Character:GetModel(), TrackObject, Data.Fade or 0, Data.Weight or 1, Data.Speed or 1)
	
	AnimTrack.Priority = Priorities[RemovedId] or Enum.AnimationPriority.Movement
	self.__Tracks[RemovedId] = AnimTrack
	
	return AnimTrack
end

function AnimatorClass:Hit()
	if self.__Tracks['Hit'] then
		self.__Tracks['Hit']:Stop(.15)
	end
	
	local TrackObject = AnimLibrary:GetAnim('Enemies.Hit.'..math.random(1, 1))
	local AnimTrack = AnimLibrary:Play(self.__Character:GetModel(), TrackObject, .05, 1, 1)

	self.__Tracks['Hit'] = AnimTrack

	return AnimTrack
end

function AnimatorClass:IsPlaying(Track: string): ()
	return self.__Tracks[Track] ~= nil and self.__Tracks[Track].IsPlaying
end

function AnimatorClass:GetTrack(Name: string): AnimationTrack
	return self.__Tracks[Name]
end

function AnimatorClass:Update(delta: number)
	local Character = self.__Character
	local Moving = Character:IsMoving() and Character:IsWalking()
	local Walk = self:GetTrack('Walk')
	local Right = self:GetTrack('WalkRight')
	local Left = self:GetTrack('WalkLeft')
	
	local Direction =  self.__Character:GetDirection()
	local Forward = math.abs(Direction:Dot(Vector3.new(0, 0, 1))) >= .8
	
	Right:AdjustWeight(Moving and math.clamp(Direction.X, 0.001, 1) or 0.001)
	Left:AdjustWeight(Moving and math.clamp(-Direction.X, 0.001, 1) or 0.001)
	Walk:AdjustWeight(Moving and Forward and 1 or 0.001)
	
	Walk:AdjustSpeed(-math.sign(Direction.Z) * 0.7)
end

function AnimatorClass:Destroy()
	
	for _, Track: AnimationTrack in self.__Tracks do
		Track:Stop()
		Track:Destroy()
	end
	
	if self.__Thread then
		self.__Thread:Disconnect()
	end
	
end

return AnimatorClass
