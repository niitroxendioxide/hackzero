--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Characters


local Types = require(Shared.Types)
local Trove = require(Shared.Utility.Trove)

local EffectsUtil = require(Shared.Utility.Effects)

--
local AppearanceClass = {} :: {[string]: (self: Types.AppearanceController, any) -> (), new: (ModelName: string, Directory: string?) -> Types.AppearanceController}
AppearanceClass.__index = AppearanceClass

function AppearanceClass.new(ModelName: string, Directory: string?): Types.AppearanceController
	local FolderToLookIn = Directory and Assets:FindFirstChild(Directory) or Assets

	if not FolderToLookIn:FindFirstChild(ModelName, true) then
		ModelName = "Template"
	end

	local World = workspace:FindFirstChild('World')
	local AssetsModel = FolderToLookIn:FindFirstChild(ModelName, true)

	if AssetsModel:IsA('Folder') then
		local RandomObj = AssetsModel:GetChildren()

		AssetsModel = RandomObj[math.random(1, #RandomObj)]
	end

	local self = setmetatable({}, AppearanceClass)
	self.__Model = AssetsModel:Clone() :: Types.Rig
	self.__Visible = true
	self.__Particles = {}
	self.__Bound_Objects = {}
	self.__TransparencyValues = {}
	self.__Trove = Trove.new()
	self.__Tilt = 0

	-- Saving values
	self.__Model.Parent = World.Entities.Appearances

	for _, Child: Instance in self.__Model:GetDescendants() do
		if Child:IsA('BasePart') or Child:IsA('Texture') or Child:IsA('Decal') then
			self.__TransparencyValues[Child] = Child.Transparency

			if Child:IsA("BasePart") then
				Child.CollisionGroup = "Characters"
			end
		end
	end

	return self
end

function AppearanceClass:GetModel()
	return self.__Model
end

function AppearanceClass:Tilt(number: number)
	self.__Tilt = number
end

function AppearanceClass:SetVisible(State: boolean)
	self.__Visible = State

	for BodyPart, Value in self.__TransparencyValues do
		local TransparencyValue = State and Value or 1

		self.__Trove:Add(EffectsUtil:Tween(BodyPart, {.4}, {Transparency = TransparencyValue}))
	end

	for _, Particle in self.__Particles do
		EffectsUtil:Toggle(Particle, State, nil, true)
	end

	for Object, Toggler in self.__Bound_Objects do
		Toggler(Object, State, 1)
	end
end

function AppearanceClass:BindObject(Object: Instance, Toggle: () -> ())
	self.__Bound_Objects[Object] = Toggle
end

function AppearanceClass:UnbindObject(Object: Instance)
	self.__Bound_Objects[Object] = nil
end

function AppearanceClass:EditPartValue(Part: BasePart, Value: number)
	self.__TransparencyValues[Part] = Value
	Part.Transparency = Value
end

function AppearanceClass:BindParticles(Part: Instance)
	if table.find(self.__Particles, Part) then
		return
	end

	table.insert(self.__Particles, Part)
end

function AppearanceClass:UnbindParticles(Part: Instance)
	local Id =  table.find(self.__Particles, Part)
	if Id then
		table.remove(self.__Particles, Id)
	end
end

function AppearanceClass:JoinTo(BasePart: BasePart)
	local Root =  self.__Model:FindFirstChild('HumanoidRootPart') or self.__Model.PrimaryPart

	local AlignPosition =  Instance.new('AlignPosition')
	local AlignOrientation = Instance.new('AlignOrientation')
	local Att0 = Instance.new('Attachment')
	local Att1 = Instance.new('Attachment')

	Att0.Parent = Root
	Att1.Parent = BasePart

	Att0.Rotation = Vector3.new(0, 0, self.__Tilt)


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
