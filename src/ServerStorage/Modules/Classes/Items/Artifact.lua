--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types.Agents)

--
local ArtifactClass = {}
ArtifactClass.__index = ArtifactClass
ArtifactClass.__tostring = function()
	return "ArtifactClass"
end

function ArtifactClass.new(Name: string): Types.AgentArtifactClass
	local self = setmetatable({}, ArtifactClass)

	self.Name = Name

	-- # Privates
	self.__Cache = {}
	self.__Events = {}

	return self
end

function ArtifactClass.Extend(self: Types.AgentArtifactClass, Level: number): Types.AgentArtifactClass
	local OldObject = self

	local newObject = ArtifactClass.new(self.Name)
	newObject.Level = Level

	-- # Privates
	newObject.__Events = table.clone(OldObject.__Events)

	return newObject;
end

function ArtifactClass.OnEffectProcess(self: Types.AgentArtifactClass, Event: (Data: Types.ProcessEventData) -> ()): ()
	if self.__Events['Effect'] ~= nil then
		return warn('function', self.__Events['Effect'], 'already bound to event: Affliction Applied')
	end

	self.__Events['Effect'] = Event

	return;
end

function ArtifactClass.OnHitProcess(self: Types.AgentArtifactClass, State: Types.HitProcessState, Event: (Data: Types.ProcessEventData) -> (number, number))
	if self.__Events[State] ~= nil then
		return warn('function', self.__Events[State], 'already bound to event: ', State)
	end

	self.__Events[State.."Hit"] = Event

	return;
end

function ArtifactClass.OnEvent(self: Types.AgentArtifactClass, State: string, Event: (Data: any) -> (number, number))
	if self.__Events[State] ~= nil then
		return warn('function', self.__Events[State], 'already bound to event: ', State)
	end

	self.__Events[State] = Event

	return;
end

function ArtifactClass.GetEventFor(self: Types.AgentArtifactClass, Name: string): ()
	return self.__Events[Name]
end

return ArtifactClass
