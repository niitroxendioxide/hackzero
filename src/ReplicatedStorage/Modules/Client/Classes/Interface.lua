--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local Fusion = require(Client.Libraries.Fusion)

--
export type Meter = Frame & {Main: ImageLabel & {UIGradient: UIGradient}, Background: ImageLabel}
export type Meter_Folder = Folder & {[string]: Meter}

--
local ComponentClass = {} :: {
	new: (Name: string, Group: string, any) -> Types.UIComponent, 
	[string]: (self: Types.UIComponent, any) -> any,
}
ComponentClass.__index = ComponentClass
ComponentClass.__tostring = function()
	return 'GUIComponent'
end

function ComponentClass.new(Name: string, Group: string): Types.UIComponent
	local self = setmetatable({}, ComponentClass)
	self.__Name = Name
	self.__Group = Group
	self.__Scope = Fusion.scoped({Value = Fusion.Value, Spring = Fusion.Spring, Observer = Fusion.Observer})
	self.__Main_Frame = nil

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

function ComponentClass:Link(): boolean
	local Player = Players.LocalPlayer
	local PlayerGui = Player.PlayerGui
	local GUIObject = PlayerGui:FindFirstChild(script.Name)

	if not(GUIObject) then
		return false;
	end

	self.__Main_Frame = GUIObject;

	return true;
end

function ComponentClass:Set(Visible: boolean)
	self.__Main_Frame.Visible = Visible
end

return ComponentClass
