--[[
	Recruit animations: Idle and Jog blended off whether it is moving, a hit reaction, and a
	cower while it hides. Movement tracks come from the model's own `Movement` folder when it
	has one, `Animations.General.Movement` otherwise (Animation:GetMovementAnim). A cower is
	only played when `Animations.Recruits.<Model>.Cower` or `Animations.Recruits.Cower` exists.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local World = require(Shared.World)
local Types = require(Shared.Types.Recruits)
local AnimLibrary = require(Client.Libraries.Animation)

--
local NON_ZERO = 0.001
local JOG_SPEED = 0.95
-- Walk speed the Jog track is timed for, an agent's jog.
local REFERENCE_SPEED = 20

local AnimatorClass = {}
AnimatorClass.__index = AnimatorClass

function AnimatorClass.new(Recruit: Types.ClientRecruitClass, Directory: string)
	local self = setmetatable({}, AnimatorClass)
	self.__Tracks = {} :: {[string]: AnimationTrack}
	self.__Directory = Directory
	self.__Recruit = Recruit
	self.__Cower = nil :: Animation?
	self.__Thread = nil :: RBXScriptConnection?

	return self
end

function AnimatorClass:Init()
	if self.__Thread then
		return
	end

	self.__Cower = AnimLibrary:GetAnim('Recruits.' .. self.__Directory .. '.Cower') or AnimLibrary:GetAnim('Recruits.Cower')

	self:Play('Idle', {Priority = Enum.AnimationPriority.Core})
	self:Play('Jog', {Weight = NON_ZERO, Speed = JOG_SPEED})

	self.__Thread = RunService.PostSimulation:Connect(function(Delta: number)
		self:Update(Delta)
	end)
end

function AnimatorClass:Play(Track: string, Data: {Fade: number?, Weight: number?, Speed: number?, Priority: Enum.AnimationPriority?}?): AnimationTrack?
	local Options = Data or {}
	local TrackObject = AnimLibrary:GetMovementAnim(self.__Directory, Track)
	local AnimTrack = AnimLibrary:Play(self.__Recruit:GetModel(), TrackObject, Options.Fade or 0, Options.Weight or 1, Options.Speed or 1)

	if not AnimTrack then
		return nil
	end

	AnimTrack.Priority = Options.Priority or Enum.AnimationPriority.Idle
	self.__Tracks[Track] = AnimTrack

	return AnimTrack
end

function AnimatorClass:Hit()
	local Previous = self.__Tracks.Hit
	if Previous then
		Previous:Stop(0.15)
	end

	local TrackObject = AnimLibrary:GetAnim('Enemies.Hit.' .. math.random(1, 8))

	self.__Tracks.Hit = AnimLibrary:Play(self.__Recruit:GetModel(), TrackObject, 0.05, 1, 1)
end

function AnimatorClass:Update(_: number)
	local Recruit = self.__Recruit
	local Moving = Recruit:IsMoving()
	local Idle = self.__Tracks.Idle
	local Jog = self.__Tracks.Jog

	if Jog then
		local _, Speed = Recruit.__Movement:GetDirection()

		Jog:AdjustWeight(if Moving then 1 else NON_ZERO)
		Jog:AdjustSpeed(JOG_SPEED * (math.max(Speed, 1) / REFERENCE_SPEED) * World:GetSpeed())
	end

	if Idle then
		Idle:AdjustWeight(if Moving then NON_ZERO else 1)
	end

	local Cowering = Recruit:GetState() == 'Hiding' and not Moving
	local Cower = self.__Tracks.Cower

	if Cowering and not Cower and self.__Cower then
		local Track = AnimLibrary:Play(Recruit:GetModel(), self.__Cower, 0.2, 1, 1)

		if Track then
			Track.Looped = true
			Track.Priority = Enum.AnimationPriority.Movement
			self.__Tracks.Cower = Track
		end
	elseif not Cowering and Cower then
		Cower:Stop(0.2)
		self.__Tracks.Cower = nil
	end
end

function AnimatorClass:Destroy()
	if self.__Thread then
		self.__Thread:Disconnect()
		self.__Thread = nil
	end

	for _, Track in self.__Tracks do
		Track:Stop()
		Track:Destroy()
	end

	table.clear(self.__Tracks)
end

return AnimatorClass
