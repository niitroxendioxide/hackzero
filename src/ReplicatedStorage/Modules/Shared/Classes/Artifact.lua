--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local ArtifactClass = {}
ArtifactClass.__index = ArtifactClass

function ArtifactClass.new(Name: string): Types.AgentArtifactClass
	local self = setmetatable({}, ArtifactClass)

	self.Name = Name
	self.Slot = 1
	self.Level = 1
	self.Stats = {}
	self.Main_Stat = {}

	-- # Privates
	self.__Events = {

	}


	return self
end

function ArtifactClass.Extend(self: Types.AgentArtifactClass, Slot: number, Level: number, Mainstat: {Types.Stat | number}, Substats: Types.Substats?)
	if typeof(Slot) ~= 'number' or Slot > 6 or Slot < 1 or #Mainstat ~= 2 then
		return
	end

	local OldObject = self

	local newObject = ArtifactClass.new(self.Name)
	newObject.Slot = Slot
	newObject.Level = Level
	newObject.Main_Stat = Mainstat
	newObject.Stats = Substats or {};

	-- # Privates
	newObject.__Count = 0
	newObject.__Events = table.clone(OldObject.__Events)

	return newObject;
end

function ArtifactClass.OnEffectProcess(self: Types.AgentArtifactClass, Event: (Effect: Types.Element, Data: Types.Process_Event_Data) -> ()): ()
	if self.__Events['Effect'] ~= nil then
		return warn('function', self.__Events['Effect'], 'already bound to event: Affliction Applied')
	end

	self.__Events['Effect'] = Event

	return;
end

function ArtifactClass.OnHitProcess(self: Types.AgentArtifactClass, State: Types.Hit_Process_State, Event: (Data: Types.Process_Event_Data) -> (number, number))
	if self.__Events[State] ~= nil then
		return warn('function', self.__Events[State], 'already bound to event: ', State)
	end
	
	self.__Events[State] = Event

	return;
end

function ArtifactClass.GetPieceCount(self: Types.AgentArtifactClass): number
	return self.__Count
end

function ArtifactClass.GetEventFor(self: Types.AgentArtifactClass, Name: string): ()
	return self.__Events[Name]
end

return ArtifactClass
