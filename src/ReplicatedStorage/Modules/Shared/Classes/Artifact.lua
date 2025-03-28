--
local Types = require('../Types')

--
local ArtifactClass = {}
ArtifactClass.__index = ArtifactClass

function ArtifactClass.new(Name: string): Types.Artifact_Class
	
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

function ArtifactClass.Extend(self: Types.Artifact_Class, Slot: number, Level: number, Mainstat: {Stat | number}, Substats: Substats?)
	if typeof(Slot) ~= 'number' or Slot > 6 or Slot < 1 or #Mainstat ~= 2 then
		return
	end
	
	local OldObject = self
	
	local self = ArtifactClass.new(self.Name)
	self.Slot = Slot
	self.Level = Level
	self.Main_Stat = Mainstat
	self.Stats = Substats or {};	
	
	-- # Privates
	self.__Count = 0
	self.__Events = table.clone(OldObject.__Events)
end

function ArtifactClass.OnEffectProcess(self: Types.Artifact_Class, Event: (Effect: Types.Element, Data: Types.Process_Event_Data) -> ()): ()
	if self.__Events['Effect'] ~= nil then
		return warn('function', self.__Events['Effect'], 'already bound to event: Affliction Applied')
	end

	self.__Events['Effect'] = Event	
end

function ArtifactClass.OnHitProcess(self: Types.Artifact_Class, State: Types.Hit_Process_State, Event: (Data: Types.Process_Event_Data) -> (number, number))
	if self.__Events[State] ~= nil then
		return warn('function', self.__Events[State], 'already bound to event: ', State)
	end
	
	self.__Events[State] = Event	
end

function ArtifactClass.GetPieceCount(self: Types.Artifact_Class): number
	return self.__Count
end

function ArtifactClass.GetEventFor(self: Types.Artifact_Class, Name: string): ()
	return self.__Events[Name]
end

return ArtifactClass
