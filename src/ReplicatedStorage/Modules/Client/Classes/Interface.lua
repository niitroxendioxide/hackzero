--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Fusion = require(Client.Libraries.Fusion)
local UIGroups = require(Client.Libraries.UIGroups)
local Inputs = require(Client.Libraries.Inputs)

--
export type Meter = Frame & {Main: ImageLabel & {UIGradient: UIGradient}, Background: ImageLabel}
export type Meter_Folder = Folder & {[string]: Meter}

--
local ComponentClass = {} :: {
	new: (Name: string, Group: string, any) -> Types.UIComponent, 
	[string]: (self: Types.UIComponent, any) -> any,
}
ComponentClass.__index = ComponentClass
ComponentClass.__type = "GUIComponent"

ComponentClass.Fusion = Fusion :: Fusion.Fusion;

function ComponentClass.new(Name: string, Group: string, Data: {KeyToBind: Enum.KeyCode?}): Types.UIComponent
	Data = Data or {};

	local self = setmetatable({}, ComponentClass)
	self.__Name = Name
	self.__Group = Group
	self.__Scope = Fusion.scoped({Value = Fusion.Value, Spring = Fusion.Spring, Observer = Fusion.Observer, peek = Fusion.peek})
	self.__Main_Frame = nil
	self.__UI_State = false
	self.__State_Change_Callback = nil
	self.__Bound_To_Key = Data.KeyToBind
	self.__Next_Events = {}

	return self
end

function ComponentClass:CheckAvailable(): boolean
	return true;
end

function ComponentClass:IsActive()
	return self.__UI_State
end

function ComponentClass:Init()
	if RunService:IsStudio() then
		print('Component', self.__Name, 'inited')
	end
end

function ComponentClass:AwaitStateChange(fn: () -> ())
	assert(typeof(fn) == 'function')

	table.insert(self.__Next_Events, fn)
end

function ComponentClass:GetScope()
	return self.__Scope
end

function ComponentClass:GetFrame()
	return self.__Main_Frame
end

function ComponentClass:Peek(a)
	return Fusion.peek(a)
end

function ComponentClass:Link(): Instance?
	local Player = Players.LocalPlayer
	local PlayerGui = Player.PlayerGui
	local GUIObject = PlayerGui:FindFirstChild(script.Name)

	return GUIObject;
end

function ComponentClass:Set(Visible: boolean?, Raw: boolean)

	if Visible == nil then
		self.__Main_Frame.Visible = not self.__Main_Frame.Visible
	else
		self.__Main_Frame.Visible = Visible
	end

	if self.__UI_State ~= self.__Main_Frame.Visible then
		for _, Event in self.__Next_Events do
			print('fired event!')
			task.spawn(Event)
		end
	end

	self.__UI_State = self.__Main_Frame.Visible

	if Visible == true then
		UIGroups:SetActiveElement(self.__Group, self.__Name)
	elseif Visible == false and UIGroups:GetActiveElementName(self.__Group) == self.__Name then
		UIGroups:SetActiveElement(self.__Group, nil)
	end


	self.__Next_Events = {}

	if (self.__State_Change_Callback ~= nil and typeof(self.__State_Change_Callback) == 'function') and not Raw then
		task.spawn(self.__State_Change_Callback, self.__UI_State)
	end
end

function ComponentClass:Bind()
	local Object = self:Link(Players.LocalPlayer)
	if Object == nil then
		return
	end

	self.__Main_Frame = Object

	UIGroups:Add(self.__Group, self)

	if self.__Bound_To_Key ~= nil and self.__Bound_To_Key ~= Enum.KeyCode.Unknown then
		Inputs:Bind(self.__Bound_To_Key, {Callback = function()
			if self.__UI_State == false and self:CheckAvailable() then
				self:Set(true)
			else
				self:Set(false)
			end
		end})
	end

	return Object ~= nil
end

function ComponentClass:Disable()
	for Key in self do
		if typeof(Key) == "function" then
			self[Key] = function() end
		end
	end

	setmetatable(self, nil)
end

function ComponentClass:BindToStateChange(Callback: (State: boolean) -> ())
	self.__State_Change_Callback = Callback
end

return ComponentClass
