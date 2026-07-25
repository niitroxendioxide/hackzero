--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Stats = game:GetService("Stats")

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AnimLibrary = require(Client.Libraries.Animation)

--
local Priorities = {Idle = Enum.AnimationPriority.Movement}
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
	self:Play('Walk', {Weight = 0.001, Speed = 1.2})
	self:Play('WalkLeft', {Weight = 0.001, Speed = 1})
	self:Play('WalkFLeft', {Weight = 0.001, Speed = 1})
	self:Play('WalkFRight', {Weight = 0.001, Speed = 1})
	self:Play('WalkRight', {Weight = 0.001, Speed = 1})

	self.__Thread = RunService.PostSimulation:Connect(function(delta: number)
		self:Update(delta)
	end)
end

function AnimatorClass:Play(Track: string, Data: Types.AnimationDataOptions)
	Data = Data or {}

	local RemovedId = tonumber(Track:sub(#Track, #Track)) ~= nil and Track:sub(1, #Track - 1) or Track
	local TrackObject = AnimLibrary:GetMovementAnim(self.__Directory, Track)
	local AnimTrack = AnimLibrary:Play(self.__Character:GetModel(), TrackObject, Data.Fade or 0, Data.Weight or 1, Data.Speed or 1)
	AnimTrack:SetAttribute("spd", AnimTrack.Speed)
	AnimTrack.Priority = Priorities[RemovedId] or Enum.AnimationPriority.Core
	self.__Tracks[RemovedId] = AnimTrack

	return AnimTrack
end

function AnimatorClass:Hit(Data: {})
	if self.__Tracks['Hit'] then
		self.__Tracks['Hit']:Stop(.15)
	end

	Data = Data or {}

	local GivenTrack = Data.Track or 'Enemies.Hit.'..math.random(1, 8)
	local TrackObject = AnimLibrary:GetAnim(GivenTrack)
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

function AnimatorClass:Update(_: number)
	local Character = self.__Character
	local Moving = Character:IsMoving() and Character:IsWalking()
	local IsAttacking = Character:GetState() ~= 'Idle'
	local Walk = self:GetTrack('Walk')
	local Right = self:GetTrack('WalkRight')
	local Left = self:GetTrack('WalkLeft')
	local Idle = self:GetTrack('Idle')
	local ForwardRight = self:GetTrack('WalkFRight')
	local ForwardLeft = self:GetTrack('WalkFLeft')
	local StatSpeed = self.__Character.__Movement.__World_Speed or 1

	local Direction =  self.__Character:GetDirection()
	local CorrectedDirection = vector.create(Direction.X, 0, math.abs(Direction.Z))
	local Tracks = {Walk, Right, Left, ForwardLeft, ForwardRight}
	local ChosenTrack = Walk

	if CorrectedDirection.X > 0 then
		if CorrectedDirection.Z > 0 then
			ChosenTrack = ForwardRight
		else
			ChosenTrack = Right
		end
	elseif CorrectedDirection.X < 0 then
		if CorrectedDirection.Z > 0 then
			ChosenTrack = ForwardLeft
		else
			ChosenTrack = Left
		end
	end

	for _, DippityTrack in Tracks do
		local Weight = Moving and DippityTrack == ChosenTrack and not IsAttacking and 1 or 0.001
		DippityTrack:AdjustSpeed(StatSpeed * DippityTrack:GetAttribute("spd"))
		DippityTrack:AdjustWeight(Weight)
	end

	Idle:AdjustWeight(not Moving and not IsAttacking and 1 or 0.001)
	Walk:AdjustSpeed(-math.sign(Direction.Z) * 0.7 * StatSpeed)
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
