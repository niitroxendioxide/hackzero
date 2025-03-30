--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Characters


local Types = require(Shared.Types)
local Trove = require(Shared.Utility.Trove)

local EffectsUtil = require(Shared.Utility.Effects)

--
local AppearanceClass = {} :: {[string]: (self: Types.AppearanceController, any) -> (), new: (ModelName: string) -> Types.AppearanceController}
AppearanceClass.__index = AppearanceClass

function AppearanceClass.new(ModelName: string): Types.AppearanceController
	assert(Assets:FindFirstChild(ModelName, true), 'Invalid model name given')
	
	local World = workspace:FindFirstChild('World')
	local AssetsModel = Assets:FindFirstChild(ModelName, true)
	
	if AssetsModel:IsA('Folder') then
		local RandomObj = AssetsModel:GetChildren()

		AssetsModel = RandomObj[math.random(1, #RandomObj)]
	end

	local self = setmetatable({}, AppearanceClass)
	self.__Model = AssetsModel:Clone() :: Types.Rig
	self.__Visible = true
	self.__TransparencyValues = {}
	self.__Trove = Trove.new()

	-- Saving values
	self.__Model.Parent = World.Entities.Appearances

	for _, Child: Instance in self.__Model:GetDescendants() do
		if Child:IsA('BasePart') or Child:IsA('Texture') or Child:IsA('Decal') then
			self.__TransparencyValues[Child] = Child.Transparency
		end
	end

	return self
end

function AppearanceClass:GetModel()
	return self.__Model
end


function AppearanceClass:SetVisible(State: boolean)
	self.__Visible = State

	for BodyPart, Value in self.__TransparencyValues do
		local TransparencyValue = State and Value or 1

		self.__Trove:Add(EffectsUtil:Tween(BodyPart, {.4}, {Transparency = TransparencyValue}))
	end
end

function AppearanceClass:JoinTo(BasePart: BasePart)
	local Root =  self.__Model:FindFirstChild('HumanoidRootPart')

	local AlignPosition =  Instance.new('AlignPosition')
	local AlignOrientation = Instance.new('AlignOrientation')
	local Att0 = Instance.new('Attachment')
	local Att1 = Instance.new('Attachment')

	Att0.Parent = Root
	Att1.Parent = BasePart


	AlignPosition.Attachment0, AlignPosition.Attachment1 = Att0, Att1
	AlignOrientation.Attachment0, AlignOrientation.Attachment1 = Att0, Att1

	AlignPosition.Responsiveness = 100
	AlignPosition.MaxForce = 1e7
	AlignOrientation.Responsiveness = 200
	AlignOrientation.MaxTorque = 1e7

	AlignPosition.Parent = Att0
	AlignOrientation.Parent = Att0

	self.__Orientation = AlignOrientation
	self.__Position = AlignPosition

	self.__Trove:Add(Att0)
	self.__Trove:Add(Att1)
end

function AppearanceClass:SetRotationResponsiveness(n)
	self.__Orientation.Responsiveness = n
end

function AppearanceClass:Destroy()
	self.__TransparencyValues = {}

	if not self.__Trove then
		return
	end

	self.__Trove:Destroy()

	--
	self.__Model:Destroy()
end

return AppearanceClass
