--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Characters = require(Database.Characters)
local GameEnum = require(Shared.GameEnum)

--
local StatesClass = {} :: {[string]: (self: Types.StatesClass, any) -> any, new: (Character: string) -> Types.StatesClass}
StatesClass.__index = StatesClass

function StatesClass.new(Character: string): Types.StatesClass
	local self = setmetatable({}, StatesClass)
	self.__Character = Character
	self.__State = 'Idle'
	self.__Base_Stats = Characters:GetSpeedStats(Character)
	self.__Threads = {}
	self.__Last_Change = os.clock()
	
	self.__Keys = {
		Sprint = false,
		Jog = false,
	}
	
	return self
end

function StatesClass:GetLastChangeTime(): number
	return (os.clock() - self.__Last_Change)
end

function StatesClass:GetVelocityMod(): number
	return math.clamp((os.clock() - self.__Last_Change) / 0.3, 0, 1)
end

function StatesClass:Switch(State: string, Time: number)
	if not table.find(GameEnum.Agent_States, State) then
		return warn('Tried to switch to invalid state')
	end
	
	local CurrentThread = self.__Threads['CurrentState']
	
	if typeof(CurrentThread) == 'thread' then
		task.cancel(CurrentThread)
	end	
	
	self.__State = State
	self.__Last_Change = os.clock()
	
	self.__Threads['CurrentState'] = task.delay(Time, function()
		self.__State = 'Idle'
		self.__Last_Change = os.clock()
		
		self.__Threads['CurrentState'] = nil
	end)

	return;
end

function StatesClass:GetKey(Key: string): boolean
	return self.__Keys[Key]
end

function StatesClass:SetKey(Key: string, Value: boolean): ()
	assert(typeof(Value) == 'boolean' or Value == nil, 'Cannot set keys to numerical values')
	
	if Value == nil then
		Value = not self.__Keys[Key]
	end
	
	self.__Keys[Key] = Value
end

function StatesClass:GetSpeed(Ignore_States: boolean)
	local CharStats = self.__Base_Stats
	
	--
	if (self.__State ~= 'Idle' and self.__State ~= 'Dashing') and not Ignore_States then
		return 0
	end
	
	if self:GetKey('Sprint') then
		return CharStats.Sprint_Speed
	elseif self:GetKey('Jog') then
		return CharStats.Jog_Speed
	end
	
	
	return CharStats.Walk_Speed or 16
end

function StatesClass:Destroy()
	
end

function StatesClass:GetState(): Types.State
	return self.__State
end

function StatesClass:GetSpeeds(): {}
	return self.__Base_Stats
end

return StatesClass
