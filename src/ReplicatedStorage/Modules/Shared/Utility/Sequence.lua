--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')
local World = require(ReplicatedStorage.Modules.Shared.World)

export type SequenceFrame = {number | (self: Sequence) -> ()}
export type SequenceFrames = {SequenceFrame}
export type Sequence = {
	__cache: {[any]: any},
	__frames: SequenceFrames,
	__name: string,

	--
	Start: (self: Sequence) -> Sequence,
	Pause: (self: Sequence) -> Sequence,
	Destroy: (self: Sequence) -> (),
	GetSpeed: (self: Sequence) -> (),

	--
	Update: (self: Sequence) -> (),

	--[[
		Runs immediately after the last frame of the sequence, regardless of its length, if the sequence is modified mid-run, this function will then run after the new last frame.
		@param function The handler that runs the post-sequence function
	]]
	After: (self: Sequence, fn: (self: Sequence) -> ()) -> Sequence,
}

--
local Sequence = {}
Sequence.__index = Sequence

function Sequence.new(Frames: SequenceFrames, Name: string?)
	local self = setmetatable({}, Sequence)
	self.__currentTime = 0
	self.__name = Name or 'default_sequence'
	self.__runContext = task.spawn
	self.__speed = 1
	self.__active = false
	self.__frames = Frames
	self.__cache = {}
	self.__onFinish = {}
	self.__playedFrames = {}
	self.__framePlayCount = {}
	self.__onWorldSpeedChange = {}

	return self
end

function Sequence:Start()
	if self.__active or #self.__playedFrames >= #self.__frames then
		return
	end

	self.__active = true

	self.__runContext(self.Update, self, RunService.Heartbeat:Wait())

	return self
end

function Sequence:GetLength(): number
	local sequence_length = 0;
	for _, frame in self.__frames do
		if typeof(frame[2]) == 'function' and sequence_length < frame[1] then
			sequence_length = frame[1] 
		elseif typeof(frame[2]) == 'number' and sequence_length < frame[2] then
			sequence_length = frame[2]
		end
	end

	return sequence_length;
end

function Sequence.Add(self: Sequence, Time: number, ...)
	if typeof(Time) ~= 'number' then
		return warn('Invalid time parameter given. Value is not a number', debug.info(2, 's'))
	end

	table.insert(self.__frames, table.pack(Time, ...))
	return;
end

function Sequence:Update(delta: number)
	if not self.__active then
		return false
	end

	if World.IsTweening then
		for _, Function in self.__onWorldSpeedChange do
			task.spawn(Function, World:GetSpeed())
		end
	end

	self.__currentTime += delta * self:GetSpeed()

	for key, frameData in self.__frames do
		if table.find(self.__playedFrames, key) then continue end

		if self.__currentTime >= frameData[1] then
			local secondKey = frameData[2]

			if typeof(secondKey) == 'function' then
				frameData[2](self, delta)

				table.insert(self.__playedFrames, key)
			else
				local handler = frameData[3]
				self.__framePlayCount[key] = (self.__framePlayCount[key] or 0) + 1

				handler(self, delta, self.__framePlayCount[key])

				if self.__currentTime >= frameData[2] then
					table.insert(self.__playedFrames, key)
				end
			end
		end
	end

	if #self.__playedFrames >= #self.__frames then
		return self:Destroy()
	end

	return self:Update(RunService.Heartbeat:Wait())
end

function Sequence:Pause()
	self.__active = false

	return self
end

function Sequence:Destroy()
	if self.__active ~= true then
		return
	end

	for _, endFunction in self.__onFinish do
		task.spawn(endFunction, self)
	end

	self.__onFinish = {}

	self.__active = false
	self.__frames = {}
end

-- Add a function after the sequence ends
function Sequence:After(fn: (self: Sequence) -> ()): Sequence
	assert(typeof(fn) == 'function', 'Invalid function given to play after sequence ends')
	
	table.insert(self.__onFinish, fn)
	
	return self
end

function Sequence:OnWorldSpeedChange(fn: (World: number) -> ())
	table.insert(self.__onWorldSpeedChange, fn)
end

function Sequence:GetSpeed()
	return self.__speed * World:GetSpeed()
end


function Sequence:SetSpeed(number: number)
	self.__speed = number
end

return Sequence
