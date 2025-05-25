--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AnimLibrary = require(Client.Libraries.Animation)

--
local Priorities = {Idle = Enum.AnimationPriority.Core, Dash = Enum.AnimationPriority.Action}
local AnimatorClass = {} :: {[string]: (self: Types.AnimatorController, any) -> any}
AnimatorClass.__index = AnimatorClass

function AnimatorClass.new(Character: Types.CharacterClass, Directory: string): Types.AnimatorController
	local self = setmetatable({}, AnimatorClass)
	self.__Tracks = {}
	self.__State_Tracks = {}
	self.__Directory = Directory
	self.__IsMoving = false
	self.__Character = Character
	self.__Angle = 0
	self.__SinceStop = os.clock()

	return self
end

function AnimatorClass:AddTrackToState(State: string, Track: AnimationTrack, Time: number)
	if self.__State_Tracks[State] == nil then
		self.__State_Tracks[State] = {}
	end

	table.insert(self.__State_Tracks[State], {Track, Time, os.clock(), Track.WeightCurrent})

	return
end

function AnimatorClass:Init()
	if self.__Thread then
		return
	end

	self:Play('Idle')
	self:Play('Sprint', {Weight = 0.001, Speed = .825})
	self:Play('Jog', {Weight = 0.001})
	self:Play('Walk', {Weight = 0.001, Speed = 0.7})

	self.__Thread = RunService.PostSimulation:Connect(function(delta: number)
		self:Update(delta)
	end)
end

function AnimatorClass:Play(Track: string, Data: Types.AnimationDataOptions)
	Data = Data or {}

	local RemovedId = Data.Name or (tonumber(Track:sub(#Track, #Track)) ~= nil and Track:sub(1, #Track - 1) or Track)
	local TrackObject = AnimLibrary:GetMovementAnim(self.__Directory, Track)
	local AnimTrack = AnimLibrary:Play(self.__Character:GetModel(), TrackObject, Data.Fade or 0, Data.Weight or 1, Data.Speed or 1)

	AnimTrack.Priority = Priorities[RemovedId] or Enum.AnimationPriority.Idle
	self.__Tracks[RemovedId] = AnimTrack

	return AnimTrack
end

function AnimatorClass:IsPlaying(Track: string): ()
	return self.__Tracks[Track] ~= nil and self.__Tracks[Track].IsPlaying
end

function AnimatorClass:GetTrack(Name: string): AnimationTrack
	return self.__Tracks[Name]
end

function AnimatorClass:Stop(Name: string)
	local Track = self:GetTrack(Name)
	
	Track:Stop()
	self.__Tracks[Name] = nil
end

function AnimatorClass:Update(delta: number)
	local Character = self.__Character
	local Moving = Character:IsMoving()
	local CurrentState = Character:GetState()
	local InIdle = CurrentState == 'Idle'
	local Sprint = self:GetTrack('Sprint')
	local Jog = self:GetTrack('Jog')
	local Walk = self:GetTrack('Walk')
	local SprintStop = self:GetTrack('SprintStop')
	local Dash = self:GetTrack('Dash')

	-- Run stop
	local Timestamp = Sprint.TimePosition > 0.15 and Sprint.TimePosition < 0.45 and 2 or 1
	if self.__IsMoving and not Moving and not self:IsPlaying('SprintStop') and Character:GetKey('Jog') and CurrentState ~= 'Attacking' then
		self:Play('SprintStop'..Timestamp, {Fade = 0.15})
		self.__SinceStop = os.clock()
	end
	
	-- Adjusting weights
	local Speed = Character:GetMovementSpeed()
	local CharStats = Character.__States:GetSpeeds()
	
	if SprintStop and os.clock() - self.__SinceStop > .2 then
		if Character.__Controller.__LastMovementVelocity.Magnitude > 0.225 and not Moving then
			SprintStop:AdjustSpeed(0)
			SprintStop.TimePosition = .2 + math.sin(math.rad(self.__Angle)) * 0.01
			SprintStop:AdjustWeight(math.clamp(Character.__Controller.__LastMovementVelocity.Magnitude / Speed, 0.001, 1))
		else
			
			SprintStop:Stop()
		end
	end
	
	for State, Tracks in self.__State_Tracks do
		for _, Track_Table in Tracks do
			local Track_Object = Track_Table[1] :: AnimationTrack
			local Time = Track_Table[2]
			local Passed_Time = os.clock() - Track_Table[3]

			if not Track_Object.IsPlaying or Track_Object.TimePosition >= Track_Object.Length then
				Track_Object:Stop(0)
				table.remove(Tracks, table.find(Tracks, Track_Table))
				continue
			end

			if self.__Character:GetState() == State or not Moving then
				Track_Object:AdjustWeight(1)
			elseif self.__Character:GetState() ~= State and Passed_Time > Time and Moving then
				Track_Object:AdjustWeight(0.001)
			end
		end
	end
	
	
	Sprint:AdjustWeight(Moving and InIdle and Speed >= CharStats.Sprint_Speed and 1 or 0.001)
	Jog:AdjustWeight(Moving and InIdle and Speed >= CharStats.Jog_Speed and Speed < CharStats.Sprint_Speed and 1 or 0.001)
	Walk:AdjustWeight(Moving and InIdle and Speed < CharStats.Jog_Speed and 1 or 0.001)
	--Walk:AdjustSpeed(math.clamp(Speed/, 0.001, 1))
	
	if Dash then
		local Timeleft = .35
		local ExpectedWeight = (Moving and Dash.TimePosition > .19) or (not Dash.IsPlaying)
		local LoweredWeight = 1 - math.max(Dash.TimePosition - Dash.Length * (1 - Timeleft), 0) / Dash.Length * Timeleft
		
		Dash:AdjustWeight(ExpectedWeight and 0.001 or LoweredWeight)
	end
	
	Sprint:AdjustSpeed(math.clamp(Character:GetMovementSpeed() / 30 * 0.825, 0, 2.5))
	
	-- Set value
	self.__IsMoving = Moving
	self.__Angle += delta * 60
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
