--[[
	@class ClientRecruit

	A recruit as the client sees it, visuals only: every decision is the server's. Between
	packets it keeps walking along the last heading it was sent, with the same
	RecruitMovement the server runs so the guess lands close. Every snap pulls it back onto
	the server's position: smoothly when the guess was close, instantly when it was not.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Statics = require(Shared.Database.Statics)
local GameEnum = require(Shared.GameEnum)
local Math = require(Shared.Utility.Math)
local SharedEffects = require(Shared.Utility.Effects)
local Types = require(Shared.Types.Recruits)
local RecruitsDatabase = require(Shared.Database.Recruits)
local MovementClass = require(Shared.Classes.Recruit.RecruitMovement)
local AppearanceClass = require(Client.Classes.Appearance)
local Effects = require(Client.Libraries.Effects)
local AnimatorClass = require(script.Animator)

--
local FULL_PIP = Color3.fromRGB(110, 200, 255)
local EMPTY_PIP = Color3.fromRGB(45, 45, 55)

local function CreateAnchor(At: CFrame, Id: number): BasePart
	local Entities = workspace.World.Entities
	local Parent = Entities:FindFirstChild('Recruits') or Instance.new('Folder')
	Parent.Name = 'Recruits'
	Parent.Parent = Entities

	local Part = Instance.new('Part')
	Part.Name = 'Recruit' .. Id
	Part.CFrame = At
	Part.Size = Vector3.one * 2
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.Transparency = 1
	Part.Parent = Parent

	return Part
end

--- Name and shield pips over its head, built in code until there is an asset for it.
local function CreateIndicator(Model: Model, DisplayName: string): BillboardGui
	local Adornee = Model:FindFirstChild('Head') or Model.PrimaryPart

	local Gui = Instance.new('BillboardGui')
	Gui.Name = 'RecruitIndicator'
	Gui.Size = UDim2.fromScale(4, 1)
	Gui.StudsOffset = Vector3.new(0, 2.25, 0)
	Gui.LightInfluence = 0
	Gui.MaxDistance = 150
	Gui.Adornee = Adornee

	local Label = Instance.new('TextLabel')
	Label.Name = 'DisplayName'
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.fromScale(1, 0.55)
	Label.Font = Enum.Font.GothamBold
	Label.TextScaled = true
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextStrokeTransparency = 0.4
	Label.Text = DisplayName
	Label.Parent = Gui

	local Pips = Instance.new('Frame')
	Pips.Name = 'Pips'
	Pips.BackgroundTransparency = 1
	Pips.Position = UDim2.fromScale(0, 0.6)
	Pips.Size = UDim2.fromScale(1, 0.3)
	Pips.Parent = Gui

	local Layout = Instance.new('UIListLayout')
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0.02, 0)
	Layout.Parent = Pips

	Gui.Parent = Adornee

	return Gui
end

--- Brief white flash on the model, the hit equivalent of the Death effect's highlight.
local function Flash(Model: Model)
	local Highlight = Instance.new('Highlight')
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillColor = Color3.new(1, 1, 1)
	Highlight.FillTransparency = 0.2
	Highlight.OutlineTransparency = 1
	Highlight.Parent = Model

	SharedEffects:Tween(Highlight, {0.25}, {FillTransparency = 1})
	SharedEffects:CleanUp(Highlight, 0.3)
end

--
local ClientRecruit = {}
ClientRecruit.__index = ClientRecruit
ClientRecruit.__tostring = function()
	return 'ClientRecruitClass'
end

--[[
	@param Id      Id the server knows it by.
	@param Name    Its kind out of `Database/Recruits`.
	@param At      Where the server has it.
	@param Visuals What to draw it as, resolved server side so mission overrides show up.
]]
function ClientRecruit.new(Id: number, Name: string, At: CFrame, Visuals: {Model: string?, Display_Name: string?, Height: number?}?): Types.ClientRecruitClass
	local Data = RecruitsDatabase:GetData(Name)
	local Drawn = Visuals or {}
	local Model = Drawn.Model or Data.Model

	local self = setmetatable({}, ClientRecruit)
	self.Name = Name

	self.__Id = Id
	self.__Owner_Id = 0
	self.__State = 'Idle'
	self.__Shield = Data.Stats.Shield
	self.__Max_Shield = Data.Stats.Shield
	self.__Display_Name = Drawn.Display_Name or Data.Display_Name
	self.__Movement = MovementClass.new(At, Data.Stats.Walk_Speed, Drawn.Height or Data.Appearance.Height)
	self.__Correction = Vector3.zero
	self.__Anchor = CreateAnchor(At, Id)

	--- Seeded off the id, so a model folder with variants gives every client the same pick.
	self.__Appearance = AppearanceClass.new(Model, 'Recruits', false, Random.new(Id))
	self.__Animator = AnimatorClass.new(self, Model)
	self.__Indicator = nil
	self.__Connection = nil

	return self
end

function ClientRecruit.Init(self: Types.ClientRecruitClass)
	if self.__Connection then
		return
	end

	local Model = self.__Appearance:GetModel()
	Model:PivotTo(self.__Anchor.CFrame)

	self.__Appearance:JoinTo(self.__Anchor)
	self.__Animator:Init()
	self.__Indicator = CreateIndicator(Model, self.__Display_Name)
	self:SetShield(self.__Shield, self.__Max_Shield)

	self.__Connection = RunService.PreRender:Connect(function(Delta: number)
		self:Update(Delta)
	end)
end

function ClientRecruit.Update(self: Types.ClientRecruitClass, Delta: number)
	self.__Movement:Update(Delta)

	--- Bleed the correction out rather than jumping onto the server's position.
	self.__Correction *= 1 - Math:SmoothAlpha(Statics.Replication_Correction_Rate, Delta)
	if self.__Correction.Magnitude < 0.01 then
		self.__Correction = Vector3.zero
	end

	self.__Anchor.CFrame = self:GetPivot()
end

function ClientRecruit.Move(self: Types.ClientRecruitClass, Direction: Vector3, Speed: number)
	self.__Movement:Move(Direction, Speed)
end

function ClientRecruit.Sync(self: Types.ClientRecruitClass, At: CFrame, Teleport: boolean?)
	local Rendered = self.__Movement.__Position + self.__Correction
	local Distance = (At.Position - Rendered).Magnitude

	if Teleport or Distance >= Statics.Replication_Snap_Distance then
		self.__Correction = Vector3.zero
		self.__Movement:PivotTo(At)
		self.__Anchor.CFrame = self:GetPivot()

		--- The model is pulled onto the anchor by physics, which would drag it across the map.
		self.__Appearance:GetModel():PivotTo(self.__Anchor.CFrame)

		return
	end

	if Distance <= Statics.Replication_Ignore_Distance then
		return
	end

	--- Take the server's position but keep drawing it where it was, Update eases the gap away.
	self.__Movement:PivotTo(At)
	self.__Correction = Rendered - At.Position
end

function ClientRecruit.DisplayHit(self: Types.ClientRecruitClass, Hits: number, Shield: number)
	self:SetShield(Shield, self.__Max_Shield)
	self.__Animator:Hit()

	local Model = self.__Appearance:GetModel()
	Flash(Model)

	--- At a position rather than the recruit itself: Indicator reuses per-id objects, and ids are shared with enemies.
	Effects:Play('Indicator', Model:GetPivot().Position, {Text = `-{Hits}`, Affliction = 'Enemy'})
end

function ClientRecruit.SetShield(self: Types.ClientRecruitClass, Shield: number, Max: number)
	self.__Shield = Shield
	self.__Max_Shield = Max

	local Indicator = self.__Indicator
	if not Indicator then
		return
	end

	local Pips = Indicator:FindFirstChild('Pips') :: Frame
	local Width = UDim2.fromScale(math.min(0.9 / math.max(Max, 1), 0.18), 1)

	for _, Pip in Pips:GetChildren() do
		local Index = tonumber(Pip.Name)

		if Index and Index > Max then
			Pip:Destroy()
		end
	end

	for Index = 1, Max do
		local Pip = (Pips:FindFirstChild(tostring(Index)) or Instance.new('Frame')) :: Frame
		Pip.Name = tostring(Index)
		Pip.LayoutOrder = Index
		Pip.BorderSizePixel = 0
		Pip.Size = Width
		Pip.BackgroundColor3 = if Index <= Shield then FULL_PIP else EMPTY_PIP
		Pip.Parent = Pips
	end
end

function ClientRecruit.SetOwner(self: Types.ClientRecruitClass, OwnerId: number)
	self.__Owner_Id = OwnerId
end

function ClientRecruit.SetState(self: Types.ClientRecruitClass, State: Types.RecruitState)
	self.__State = State
end

function ClientRecruit.IsOwner(self: Types.ClientRecruitClass, Player: Player): boolean
	return self.__Owner_Id ~= 0 and self.__Owner_Id == (Player:GetAttribute('ReplicationId') :: number)
end

function ClientRecruit.IsMoving(self: Types.ClientRecruitClass): boolean
	return self.__Movement:IsMoving()
end

function ClientRecruit.GetId(self: Types.ClientRecruitClass): number
	return self.__Id
end

function ClientRecruit.GetState(self: Types.ClientRecruitClass): Types.RecruitState
	return self.__State
end

function ClientRecruit.GetPivot(self: Types.ClientRecruitClass): CFrame
	return self.__Movement:GetPivot() + self.__Correction
end

function ClientRecruit.GetModel(self: Types.ClientRecruitClass): Model
	return self.__Appearance:GetModel()
end

--- @param Reason `GameEnum.EntityRemoveReason`, a defeat plays the Death effect.
function ClientRecruit.Destroy(self: Types.ClientRecruitClass, Reason: number?)
	if self.__Connection then
		self.__Connection:Disconnect()
		self.__Connection = nil
	end

	if self.__Indicator then
		self.__Indicator:Destroy()
		self.__Indicator = nil
	end

	--- Death clones the model before anything yields, so destroying it right after is safe.
	if Reason == GameEnum.EntityRemoveReason.Defeated then
		Effects:Play('Death', self)
	end

	self.__Animator:Destroy()
	self.__Appearance:Destroy()
	self.__Anchor:Destroy()
end

return ClientRecruit
