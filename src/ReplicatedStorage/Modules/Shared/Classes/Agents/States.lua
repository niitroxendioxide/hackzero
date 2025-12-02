--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
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
	self.__Current_Skill = ''
	self.__Current_State_Max_Time = 0.001
	self.__Last_Dash_State = os.clock()

	self.__Keys = {
		Sprint = false,
		Jog = false,
	}

	return self
end

function StatesClass:GetCurrentSkill()
	return self.__Current_Skill
end

function StatesClass:SetCurrentSkill(Name: string)
	self.__Current_Skill = Name
end

function StatesClass:GetLastChangeTime(): number
	return (os.clock() - self.__Last_Change)
end

function StatesClass:CanStartMoving(): boolean
	return self:GetLastChangeTime() > 0.25
end

function StatesClass:GetVelocityMod(): number
	local Mod =  math.clamp((os.clock() - self.__Last_Change - 0.3) / 0.1, 0, 1)

	return self:CanStartMoving() and 1 or 0 -- od
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
	self.__Current_State_Max_Time = Time

	if self.__State == 'Attacking' then
		self.__Last_Change = os.clock()
	end

	self.__Threads['CurrentState'] = task.delay(Time, function()
		self.__State = 'Idle'
		if State == 'Attacking' then
			self.__Last_Change = os.clock()
		elseif State == "Dashing" then
			self.__Last_Dash_State = os.clock()
		end

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
		local Max = self:GetKey("Sprint") and CharStats.Sprint_Speed or self:GetKey("Jog") and CharStats.Jog_Speed or CharStats.Walk_Speed
		local Time = 1 - math.min((os.clock() - self.__Last_Change) / self.__Current_State_Max_Time, 1) * 0.9

		return Max * Time
	end

	local TimePassed = (os.clock() - self.__Last_Dash_State)
	local DashSpeedBoost = Statics.Dash_Speed_Buff
	local DashBoostEffect = self.__State == "Dashing" and DashSpeedBoost or (1 - math.min(TimePassed, Statics.Dash_Speed_Buff_Vanish_Time)) * DashSpeedBoost

	if self:GetKey('Sprint') or Ignore_States then
		return CharStats.Sprint_Speed + (CharStats.Sprint_Speed * DashBoostEffect * (Ignore_States and 0 or 1))
	elseif self:GetKey('Jog') then
		return CharStats.Jog_Speed + (CharStats.Jog_Speed * DashBoostEffect)
	end

	local WalkSpeed = CharStats.Walk_Speed or 16
	return WalkSpeed + (WalkSpeed * DashBoostEffect)
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
