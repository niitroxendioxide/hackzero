
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Characters


local Types = require(Shared.Types)
local Trove = require(Shared.Utility.Trove)

local EffectsUtil = require(Shared.Utility.Effects)

--
local AppearanceClass = {} :: {[string]: (self: Types.AppearanceController, any) -> (), new: (ModelName: string, Directory: string?, BeginTransparet: boolean?) -> Types.AppearanceController}
AppearanceClass.__index = AppearanceClass

function AppearanceClass.new(ModelName: string, Directory: string?, BeginTransparet: boolean?): Types.AppearanceController
	local FolderToLookIn = Directory and Assets:FindFirstChild(Directory) or Assets

	if not FolderToLookIn:FindFirstChild(ModelName, true) then
		ModelName = "Template"
	end

	local World = workspace:FindFirstChild('World')
	local AssetsModel = FolderToLookIn:FindFirstChild(ModelName, true)
	if AssetsModel == nil then
		AssetsModel = Assets.Agents:FindFirstChild('Template')
	end

	if AssetsModel and AssetsModel:IsA('Folder') then
		local RandomObj = AssetsModel:GetChildren()

		AssetsModel = RandomObj[math.random(1, #RandomObj)]
	end

	local self = setmetatable({}, AppearanceClass)
	self.__Tilt = 0
	self.__Extra_Height = 0
	self.__Current_Height_Tween = nil :: Tween?
	self.__Current_Height_Thread = nil :: thread?
	self.__Model = AssetsModel:Clone() :: Types.Rig
	self.__Visible = true
	self.__Particles = {}
	self.__Bound_Objects = {}
	self.__TransparencyValues = {}
	self.__Trove = Trove.new()

	-- Saving values
	self.__Model.Parent = World.Entities.Appearances

	for _, Child: Instance in self.__Model:GetDescendants() do
		if Child:IsA('BasePart') or Child:IsA('Texture') or Child:IsA('Decal') then
			self.__TransparencyValues[Child] = Child.Transparency
			if BeginTransparet then
				(Child :: BasePart).Transparency = 1
			end

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



function AppearanceClass:Raise(Factor: number, Time: number, Instant: boolean?): ()
	self.__Extra_Height += Factor;

	if self.__Current_Height_Thread then
		task.cancel(self.__Current_Height_Thread)
	end

	
	--
	local tween_time = (Instant == true and 0) or (self.__Extra_Height / 16)
	local new_tween = EffectsUtil:Tween(self.__Root_Attachment, {tween_time, 'Quart'}, {Position = vector.create(0, -self.__Extra_Height)})
	self.__Current_Height_Tween = new_tween
	
	self.__Current_Height_Thread = task.delay(Time, function()
		self:__clean_heights();
	end)
end

function AppearanceClass:GetAddedHeight()
	return self.__Extra_Height
end

function AppearanceClass:Land()
	if (self.__Current_Height_Tween) then
		self.__Current_Height_Tween:Pause()
	end

	self:__clean_heights()
end

function AppearanceClass:__clean_heights()
	local timeToFall = (self.__Extra_Height / 12)

	local Land_Tween = EffectsUtil:Tween(self.__Root_Attachment, {timeToFall, 'Quart', 'In'}, {Position = vector.zero})
	if self.__Current_Height_Tween then
		self.__Current_Height_Tween:Destroy()
		self.__Current_Height_Tween = Land_Tween
	end

	self.__Extra_Height = 0;
	self.__Current_Height_Thread = nil;
end

function AppearanceClass:IsRaised()
	return self.__Extra_Height > 0;
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

function AppearanceClass:EditPartValue(Part: BasePart, Value: number, DontChange: boolean?)
	self.__TransparencyValues[Part] = Value

	if DontChange then
		return
	end
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

function AppearanceClass:JoinTo(BasePart: BasePart, Responsiveness: number?)
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
	AlignOrientation.Responsiveness = Responsiveness or 100
	AlignOrientation.MaxTorque = 1e7

	AlignPosition.Parent = Att0
	AlignOrientation.Parent = Att0

	self.__Orientation = AlignOrientation
	self.__Position = AlignPosition
	self.__Root_Attachment = Att0
	self.__Target_Attachment = Att1

	self.__Trove:Add(Att0)
	self.__Trove:Add(Att1)
end

function AppearanceClass:SetRotationResponsiveness(n)
	self.__Orientation.Responsiveness = n
end

function AppearanceClass:Destroy(IncludeFade: boolean?)
	self.__Model.PrimaryPart.Anchored = true

	if IncludeFade then
		self:SetVisible(false)

		task.delay(1, function(): ()
			self:Destroy()
		end)

		return
	end

	self.__TransparencyValues = {}

	if not self.__Trove then
		return
	end

	self.__Trove:Destroy()

	--
	self.__Model:Destroy()
end

return AppearanceClass
