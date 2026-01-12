--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService('TweenService')

--
local EffectUtil = {}

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Random_Number = Random.new()

local Mock = require(Shared.Utility.Mock)
local World = require(script.Parent.Parent.World)
local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
local CameraShaker = require(Client.Utility.Libraries.CameraShaker)

local Effects_Folder = workspace:WaitForChild('World'):WaitForChild('Effects')
local Assets = ReplicatedStorage.Assets.Effects


export type TweenGoals = {
	Size: (Vector3 | UDim2 | vector)?,
	CFrame: CFrame?,
	Position: (Vector3 | UDim2 | vector)?,
	Orientation: Vector3?,
	Transparency: number?,
	Brightness: number?,
	Range: number?,
	[string]: any?,
}

function EffectUtil:Tween(Object: Instance, Info: {number | string | boolean | nil}, Goals: TweenGoals)
	--
	local Time, Ease, Direction = Info[1] :: number, (Info[2] or 'Linear') :: string, (Info[3] or 'Out') :: string;
	local Reverse, Delay = Info[5] or false, Info[6] or 0
	local NewInfo = typeof(Info) == 'TweenInfo' and Info or TweenInfo.new(
		Time,
		Enum.EasingStyle[Ease] :: Enum.EasingStyle,
		Enum.EasingDirection[Direction] :: Enum.EasingDirection,
		0,
		Reverse,
		Delay
	)

	--
	local Tween = TweenService:Create(Object, NewInfo, Goals)
	Tween:Play()

	Tween.Completed:Once(function()
		Tween:Destroy()
	end)

	return Tween
end

function EffectUtil:FromGui<T>(name: string): T & GuiObject
	local PlayerGui = Players.LocalPlayer.PlayerGui

	return PlayerGui:FindFirstChild("Effects"):FindFirstChild(name)
end


function EffectUtil:RecolorToGroundColor(At: Vector3, Particles: {})
	local MapParams = World:GetMapParams()
	local Cast = workspace:Raycast(At, vector.create(0, -1000), MapParams )

	if Cast then
		local Seq = ColorSequence.new(Cast.Instance.Color)
		for _, Particle in Particles do
			Particle.Color = Seq
		end
	end

end

function EffectUtil:CleanUp(Object: any, Time: number)
	return task.delay(Time, function()
		local typeOf = typeof(Object)

		if typeOf == 'Instance' or (typeOf == 'table' and Object.Destroy) then
			Object:Destroy()
		elseif typeOf == 'RBXScriptConnection' then
			Object:Disconnect()
		elseif typeOf == 'function' then
			Object()
		elseif typeOf == 'thread' and (coroutine.running() ~= Object) then
			task.cancel(Object)
		end
	end)
end

function EffectUtil:HueShift(Obj: BasePart, Shift: number, Filter: ((a: ParticleEmitter) -> (number))?)
	for _, Particle: Instance in Obj:GetDescendants() do
		if not Particle:IsA("ParticleEmitter") then
			continue
		end

		local HueShiftVal = Filter and Filter(Particle) or Shift
		if HueShiftVal == 0 then
			continue
		end

		local Points = {}
		for _, Keypoint in Particle.Color.Keypoints do
			local Hue, S, V	= Keypoint.Value:ToHSV()
			local New = Hue + (HueShiftVal / 360)

			if New > 1 then
				New -= 1
			elseif New < 0 then
				New += 1
			end
			local Color = Color3.fromHSV(New, S, V)

			table.insert(Points, ColorSequenceKeypoint.new(Keypoint.Time, Color))
		end

		Particle.Color = ColorSequence.new(Points)
		table.clear(Points)
	end
end

function EffectUtil:MultiClean(Objects: {any}, Time: number)
	for _, newObj in Objects do
		EffectUtil:CleanUp(newObj, Time)
	end
end

function EffectUtil:CastMapRaycast(from: Vector3 | vector | CFrame, dir: vector | Vector3)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {workspace.World.Map}

	from = (if typeof(from) == 'CFrame' then from.Position else from) :: Vector3

	return workspace:Raycast(from, dir, Params)
end

function EffectUtil:SetRandomSeed(n: number)
	Random_Number = Random.new(n)
end

function EffectUtil:Random(min: number, max: number): (number)
	return Random_Number:NextNumber(min, max)
end

function EffectUtil:RandomInt(min: number, max: number): (number)
	return Random_Number:NextInteger(min, max)
end

function EffectUtil:RandomV3(): Vector3
	return Random_Number:NextUnitVector()
end

--[[
	Returns the waited time divided by world speed, so it's useful for effects
]]
function EffectUtil:Wait(time_to_wait: number)
	return task.wait(time_to_wait) / World:GetSpeed()
end

function EffectUtil:Create<T>(Asset: T & Instance, Time: number?): (T, thread)
	local Dir = string.split(debug.info(2, 's'), '.')
	local Name = Dir[#Dir]

	if not Effects_Folder:FindFirstChild(Name) then
		local New_Folder = Instance.new('Folder')
		New_Folder.Name = Name
		New_Folder.Parent = Effects_Folder
	end

	local Cloned = (Asset :: Instance):Clone()
	Cloned.Parent = Effects_Folder:FindFirstChild(Name)

	local DeleteThread = EffectUtil:CleanUp(Cloned, Time or 10)

	return Cloned :: T, DeleteThread
end

local FACES = {
	[Enum.NormalId.Front] = Enum.NormalId.Back,
	[Enum.NormalId.Back] = Enum.NormalId.Front,
	[Enum.NormalId.Left] = Enum.NormalId.Right,
	[Enum.NormalId.Right] = Enum.NormalId.Left,
	[Enum.NormalId.Bottom] = Enum.NormalId.Top,
	[Enum.NormalId.Top] = Enum.NormalId.Bottom,
}

function EffectUtil:ReverseEmitter(Particle: ParticleEmitter)
	local Face = FACES[Particle.EmissionDirection]
	if not Face then
		return
	end

	Particle.EmissionDirection = Face
end

function EffectUtil:TweenModel(Model: Model, ScaleGoal: number, Time: number, Style: string?, Direction: string?)
	
	task.spawn(function()
		local StartScale = Model:GetScale()
		local ActiveTime = 0;
		local EaseStyle = Enum.EasingStyle[Style or 'Quad']
		local EaseDirection = Enum.EasingDirection[Direction or 'Out']

		while ActiveTime <= Time do
			ActiveTime += EffectUtil:Wait()

			local TotalTime = ActiveTime / Time;
			local Alpha = TweenService:GetValue(TotalTime, EaseStyle, EaseDirection)

			Model:ScaleTo(StartScale + (ScaleGoal - StartScale) * Alpha)
		end
			

	end)

end

function EmitObj(Objects: ParticleEmitter)
	local GraphicSettings = math.max(UserSettings().GameSettings.SavedQualityLevel.Value / 10, 0.3)
	local CorrectedAmount = math.ceil(Objects:GetAttribute('EmitCount') * GraphicSettings)

	Objects:Emit(CorrectedAmount)
end

function EffectUtil:Emit(Asset: Instance, Light: boolean?): ()
	local WorldSpeed = World:GetSpeed() :: number
	if Asset:IsA('ParticleEmitter') then
		local Delay = Asset:GetAttribute('EmitDelay') or 0
		task.delay( Delay / WorldSpeed, EmitObj, Asset)

		return;
	end

	for _, Objects in Asset:GetDescendants() do
		if Objects:IsA('ParticleEmitter') then

			local Delay = Objects:GetAttribute('EmitDelay') or 0
			task.delay( Delay / WorldSpeed, EmitObj, Objects)
		elseif Objects:IsA('PointLight') and Light then
			EffectUtil:Tween(Objects, {.5 / WorldSpeed}, {Brightness = 0})
		end
	end
end

function EffectUtil.TableShortcut(tab: {})
	return tab
end

function EffectUtil:CreateRocks(RaycastResult: RaycastResult, Size: Vector3 | vector, Count: number | {number}, Range: number, Rotation: {number}, Parent: Instance?)
	local RocksToCreate = typeof(Count) == 'table' and Random_Number:NextInteger(Count[1], Count[2]) or Count
	local Center = RaycastResult.Position
	local Base = RaycastResult.Instance
	local Normal = RaycastResult.Normal

	local RangeError = (360 / RocksToCreate)
	local RockItems = Assets.General.Rocks:GetChildren()

	for i = 1, RocksToCreate do
		local Angle = math.rad((360 / RocksToCreate) * i  + Random_Number:NextNumber(-RangeError/1.5, RangeError/1.5));
		local Distance = typeof(Range) == 'table' and Random_Number:NextNumber(Range[1], Range[2]) or Range;
		local BasePosition = Center + Vector3.new(math.cos(Angle) * Distance, 0, math.sin(Angle) * Distance)
		local XRot = math.rad(Random_Number:NextNumber(Rotation[1], Rotation[2]))
		
		local RockCreated = RockItems[math.random(1, #RockItems)]:Clone() --Instance.new("Part")
		local RockSize = Size * vector.create(Random_Number:NextNumber(0.8, 1.2), Random_Number:NextNumber(0.8, 1.2), Random_Number:NextNumber(0.8, 1.2))
		RockCreated.Size = RockSize * 0.75;


		local RockBaseCFrame = CFrame.lookAt(BasePosition, Center) * CFrame.new(0, RockCreated.Size.Y/2, Distance)
		local RockGoalCFrame = (CFrame.lookAt(BasePosition, Center) * CFrame.new(0, RockCreated.Size.Y/2, 0)) * CFrame.Angles(XRot * 0.5, 0, 0)
		RockCreated.CFrame =  RockBaseCFrame;
		RockCreated.CanCollide = false;
		RockCreated.Anchored = true;
		RockCreated.Material = Base.Material;
		RockCreated.Color = Base.Color;
		RockCreated.Parent = Parent or workspace.World.Effects

		EffectUtil:Tween(RockCreated, { Random_Number:NextNumber(0.15, 0.25), 'Back' }, { Size = RockSize })
		EffectUtil:Tween(RockCreated, { 0.2, 'Quint' }, {CFrame = RockGoalCFrame * CFrame.Angles(0, Random_Number:NextNumber(-math.pi * 0.25, math.pi * 0.25), 0)})

		task.delay(2.5, function()
			EffectUtil:Tween(RockCreated, { 0.7, 'Cubic', 'InOut' }, {Position = RockCreated.Position - Normal * 2.5})
			EffectUtil:Tween(RockCreated, { 0.5, 'Cubic', 'InOut' }, {Size = Vector3.zero})

			EffectUtil:CleanUp(RockCreated, 1.5)
		end)
	end
end

function EffectUtil:RecolorSmoke(RaycastResult: RaycastResult, Particles: {Instance | ParticleEmitter})
	for _, Particle in Particles do
		if Particle:HasTag('Smoke') then
			Particle.Color = ColorSequence.new(RaycastResult.Instance.Color)
		end
	end
end

function EffectUtil:ShootRocks(RaycastResult: RaycastResult, Amount: number | {number}, Speed: number | {number}, Parent: Instance?)
	local RocksToCreate = typeof(Amount) == 'table' and Random_Number:NextInteger(Amount[1], Amount[2]) or Amount
	local Center = RaycastResult.Position
	local Base = RaycastResult.Instance
	local Normal = RaycastResult.Normal

	local RangeError = (360 / RocksToCreate)

	for i = 1, RocksToCreate do
		local SpeedRange = typeof(Speed) == 'table' and Random_Number:NextNumber(Speed[1], Speed[2]) or Speed
		local Angle = math.rad((360 / RocksToCreate) * i  + Random_Number:NextNumber(-RangeError/1.5, RangeError/1.5));
		
		local RockCreated = Instance.new("Part")
		local RockSize = vector.one * Random_Number:NextNumber(0.8, 1.2)
		RockCreated.Size = RockSize * 0.75;
		RockCreated.CFrame = CFrame.lookAlong(Center, Normal);
		RockCreated.CanCollide = true;
		RockCreated.Material = Base.Material;
		RockCreated.Color = Base.Color;
		RockCreated.Parent = Parent or workspace.World.Effects;

		local Bv = Instance.new("BodyVelocity")
		Bv.Velocity = (CFrame.new(Center) * CFrame.Angles(math.rad(45), Angle, 0)).LookVector * SpeedRange
		Bv.MaxForce = vector.one * math.huge;
		Bv.Parent = RockCreated

		local Bang = Instance.new("BodyAngularVelocity")
		Bang.AngularVelocity = Random_Number:NextUnitVector() * (SpeedRange * Random_Number:NextNumber(0.8, 1.2))
		Bang.MaxTorque = vector.one * math.huge;
		Bang.Parent = RockCreated

		EffectUtil:CleanUp(Bv, 0.15);
		EffectUtil:CleanUp(Bang, 0.15);
		task.delay(1.25, function()
			EffectUtil:Tween(RockCreated, { 0.5, 'Quad' }, {Size = vector.zero})
		end)
	end
end

function EffectUtil:Weld(Object: BasePart, Welded: BasePart)
	local Weld = Instance.new('WeldConstraint')
	Weld.Part0 = Object
	Weld.Part1 = Welded
	Weld.Parent = Object

	return Weld
end

function EffectUtil:GetParent(Name: string?): Instance
	local WorldFolder = workspace:FindFirstChild("World"):: Folder

	if Name then
		return WorldFolder.Effects:FindFirstChild(Name) or WorldFolder.Effects;
	end

	return WorldFolder.Effects
end

function EffectUtil:Toggle(Object: Instance, State: boolean, Filter: ((Object: ParticleEmitter | Beam | Instance) -> (boolean))?, IncludeLights: boolean?)
	for _, Child in Object:GetDescendants() do
		if not (Child:IsA('ParticleEmitter') or Child:IsA('Beam') or (IncludeLights and Child:IsA("PointLight"))) then
			continue
		end

		if (Filter and Filter(Object)) or Filter == nil then
			Child.Enabled = State
		end
	end
end

function EffectUtil:Quad(p0, p1, p2, t)
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

function EffectUtil:ShakeCamera(Preset: string)
	local IsCameraShakeEnabled = Settings:Get("CameraShake", "Graphics");
	if not IsCameraShakeEnabled then
		return Mock;
	end


	local Camera = workspace.CurrentCamera
	local NewCamShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCf)
		Camera.CFrame = Camera.CFrame * shakeCf
	end)

	NewCamShake:Start()
	NewCamShake:Shake(CameraShaker.Presets[Preset]);

	return NewCamShake;
end

function EffectUtil:MoveProjectile(Model: Model, Size: vector, Speed: number, Time: number, Hit: () -> (boolean))
	local Loop do
		local Max_Time = 0;
		local Params = World:GetEnemyColliderParams(true)

		Loop = RunService.PostSimulation:Connect(function(Delta: number)  
			local DeltaTime = Delta * World:GetSpeed()
			Max_Time += DeltaTime

			if Max_Time >= Time then
				Loop:Disconnect()
				return;
			end

			Model:PivotTo(Model:GetPivot() * CFrame.new(0, 0, -DeltaTime * Speed))

			--
			local PartBounds = workspace:GetPartBoundsInBox(Model:GetPivot(), Size, Params)
			if #PartBounds > 0 then
				local Stop = Hit()

				if Stop then
					Loop:Disconnect()

					return;
				end
			end
		end)
	end
end

function EffectUtil:ForModelParts(Model: Model, Functions: { [string]: (BasePart) -> () })
	if not Functions then
		return;
	end

	for _, Part in Model:GetChildren() do
		if Functions[Part.Name] then
			Functions[Part.Name](Part);
		end
	end

end

return EffectUtil
