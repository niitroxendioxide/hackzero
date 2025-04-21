--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Fusion = require(Client.Libraries.Fusion)
local UIGroups = require(Client.Libraries.UIGroups)

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

function ComponentClass.new(Name: string, Group: string): Types.UIComponent
	local self = setmetatable({}, ComponentClass)
	self.__Name = Name
	self.__Group = Group
	self.__Scope = Fusion.scoped({Value = Fusion.Value, Spring = Fusion.Spring, Observer = Fusion.Observer, peek = Fusion.peek})
	self.__Main_Frame = nil
	self.__State_Change_Callback = nil

	return self
end

function ComponentClass:Init()
	print('Component', self.__Name, 'inited')
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

function ComponentClass:Set(Visible: boolean?)

	if Visible == nil then
		self.__Main_Frame.Visible = not self.__Main_Frame.Visible
	else
		self.__Main_Frame.Visible = Visible
	end

	if Visible == true then
		UIGroups:SetActiveElement(self.__Group, self.__Name)
	elseif Visible == false and UIGroups:GetActiveElementName(self.__Group) == self.__Name then
		UIGroups:SetActiveElement(self.__Group, nil)
	end


	if self.__State_Change_Callback ~= nil and typeof(self.__State_Change_Callback) == 'function' then
		self.__State_Change_Callback(Visible)
	end
end

function ComponentClass:Bind()
	local Object = self:Link()

	self.__Main_Frame = Object

	UIGroups:Add(self.__Group, self)

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
