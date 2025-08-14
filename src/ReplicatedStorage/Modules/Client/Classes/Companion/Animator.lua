--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Companions)
local DefaultTypes = require(Shared.Types)
local AnimLibrary = require(Client.Libraries.Animation)

--
local Priorities = {Idle = Enum.AnimationPriority.Core}
local AnimatorClass = {}
AnimatorClass.__index = AnimatorClass

function AnimatorClass.new(CompanionObject: Types.CompanionClass, Name: string): DefaultTypes.AnimatorController
	local self = setmetatable({}, AnimatorClass)
	self.__Tracks = {}
	self.__Name = Name
	self.__IsMoving = false
	self.__Character = CompanionObject
	self.__Angle = 0
	self.__SinceStop = os.clock()

	return self
end

function AnimatorClass:Init()
	if self.__Thread then
		return
	end

	self:Play('Idle')
	self:Play('Running', {Weight = 0.001, Speed = 0.7})

	self.__Thread = RunService.PostSimulation:Connect(function(delta: number)
		self:Update(delta)
	end)
end

function AnimatorClass:Play(Track: string, Data: DefaultTypes.AnimationDataOptions)
	Data = Data or {}

	local RemovedId = tonumber(Track:sub(#Track, #Track)) ~= nil and Track:sub(1, #Track - 1) or Track
	local TrackObject = AnimLibrary:GetCompanionAnimation(self.__Name, Track)
	local AnimTrack = AnimLibrary:Play(self.__Character:GetModel(), TrackObject, Data.Fade or 0, Data.Weight or 1, Data.Speed or 1)

	AnimTrack.Priority = Priorities[RemovedId] or Enum.AnimationPriority.Movement
	self.__Tracks[RemovedId] = AnimTrack

	return AnimTrack
end

function AnimatorClass:IsPlaying(Track: string): ()
	return self.__Tracks[Track] ~= nil and self.__Tracks[Track].IsPlaying
end

function AnimatorClass:GetTrack(Name: string): AnimationTrack
	return self.__Tracks[Name]
end

function AnimatorClass:Update(_: number)
	local Character = self.__Character
	local Moving = Character:IsMoving()
	local Running = self:GetTrack('Running')


	Running:AdjustWeight(Moving and 1 or 0.001)
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
