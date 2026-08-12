--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService('UserInputService')

local Shared = ReplicatedStorage.Modules.Shared
local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local World = require(Shared.World)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)

--
local Rad, Clamp = math.rad, math.clamp
local Settings = {
	Offset = Vector3.new(0, 1.5),

	Max_Zoom = 50,
	Min_Zoom = 10,
	Max_Angle = 80,
	Min_Angle = -45,

	Sensitivity = 0.35,
	FieldOfView = 60,
	ConsoleSensitivity = 3,
}

local Camera = {
	__Rotation = Vector2.zero,
	__Position = Vector3.zero,
	__Zoom = 22,
	__Current_Zoom = 22,
	__Track_Type = 1,
	__Subject = nil,
	__Inited = false,
	__UsedBy = nil,
	__Target_Part = "Head",
	__Focused = true,
	__Using_fov = false,
	__Delta = 24,
	__Delta_thread = nil,
	__LookAtPart = nil,
	
	__ZoomThread = nil,
	__Moving_Delta = Vector2.new(),
	__Enemies_Blocking_Vision = {},
}

function Camera:ResetZoom()
	if Camera.__ZoomThread ~= nil and Camera.__ZoomThread ~= coroutine.running() then
		task.cancel(Camera.__ZoomThread)
	end

	Camera.__Zoom = 22
	Camera.__ZoomThread = nil
end

function Camera:UseZoom(Time: number, Value: number)
	Camera.__Zoom = Value;

	if Camera.__ZoomThread then
		task.cancel(Camera.__ZoomThread)
	end

	Camera.__ZoomThread = task.delay(Time, function()
		Camera:ResetZoom()
	end)
end

function Camera:RotateTo(GivenCFrame: CFrame, RotationOnly: boolean)
	local Pitch, Yaw = GivenCFrame:ToOrientation()
	Camera.__Rotation = Vector2.new(-Yaw, -Pitch)

	if not RotationOnly then
		Camera.__Position = GivenCFrame.Position
	end
end

function Camera:StartAcceleration(Time: number, StartupTime: number)
	if Camera.__Delta_thread then
		task.cancel(Camera.__Delta_thread)
	end

	StartupTime = StartupTime or 0.25

	local GoalTime = Time + (StartupTime)
	Camera.__Delta = 0
	Camera.__Delta_thread = task.spawn(function()
		local time_passed = os.clock();
		while (os.clock() - time_passed) < GoalTime do
			local Alpha = TweenService:GetValue((os.clock() - time_passed) / GoalTime - (StartupTime), Enum.EasingStyle.Linear, Enum.EasingDirection.In)
			Camera.__Delta = math.lerp(0, 24, Alpha)
			
			task.wait()
		end
	end)
end

function Camera:Init()
	if Camera.__Inited then
		return
	end

	Camera.__Inited = true

	local ParamsNew = OverlapParams.new()
	ParamsNew.FilterDescendantsInstances = {
		workspace.World:WaitForChild('Entities'):WaitForChild('Colliders'),
	}
	ParamsNew.FilterType = Enum.RaycastFilterType.Include
	Camera.__Enemy_Params = ParamsNew

	UserInputService.TouchRotate:Connect(function(_: {any}, _: number, _: number, _: Enum.UserInputState, _: boolean) 

	end)

	UserInputService.WindowFocusReleased:Connect(function()
		Camera.__Focused = false
	end)

	UserInputService.WindowFocused:Connect(function()
		Camera.__Focused = true
	end)

	UserInputService.InputChanged:Connect(function(Input, Gp)
		if Gp then
			return
		end

		--
		if (Input.UserInputType == Enum.UserInputType.MouseMovement) and (Camera.__UsedBy == nil) and (Camera.__LookAtPart == nil) then
			local MouseDelta = UserInputService:GetMouseDelta()
			
			Camera.__Rotation += MouseDelta*Rad(Settings.Sensitivity)
			Camera.__Rotation = Vector2.new(Camera.__Rotation.X, Clamp(Camera.__Rotation.Y, Rad(Settings.Min_Angle), Rad(Settings.Max_Angle)))
		elseif Input.UserInputType == Enum.UserInputType.Gamepad1 and Input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local Delta = Vector2.new(Input.Position.X, Input.Position.Y)
			Camera.__Moving_Delta = Delta
		end
	end)
end

function Camera:ChangePartTrackingType(Type: number)
	Camera.__Track_Type = math.clamp(Type, 1, 2)
end

function Camera:SetSubject(Target: Model)
	assert(typeof(Target) == 'Instance' and Target:IsA('Model'), 'Cannot set subject to a non-model')

	self.__Subject = Target
end

function Camera:SetTargetPart(TargetPart: string)
	self.__Target_Part = TargetPart
end

function Camera:SetLookAtPart(p_LookAtPart: BasePart)
	local Previous = self.__LookAtPart
	if typeof(Previous) == 'Instance' and Previous:IsA('BasePart') then
		local Indicator = Previous:FindFirstChild('LockOn')
		if Indicator then
			local UIScale = Indicator.GUI.Circle.UIScale;
			Indicator.Name = '__destroying'
			Effects:Tween(UIScale, { 0.45, 'Quad' }, {Scale = 0})

			Effects:CleanUp(Indicator, 0.45)
		end
	end

	if (p_LookAtPart == self.__LookAtPart and p_LookAtPart ~= nil) or p_LookAtPart == nil or typeof(p_LookAtPart) ~= 'Instance' or not p_LookAtPart:IsA('BasePart') then
		
		self.__LookAtPart = nil;
		
		return
	end

	self.__LookAtPart = p_LookAtPart;

	---
	local LockOnEffect = ReplicatedStorage.Assets.Effects.General:FindFirstChild('LockOn')
	if LockOnEffect then
		LockOnEffect = LockOnEffect:Clone();

		local Circle = LockOnEffect.GUI.Circle
		local UIScale = Circle.UIScale;
		UIScale.Scale = 0;
		Effects:Tween(UIScale, { 0.45, 'Back' }, {Scale = 1})

		Circle.OuterCircle.BorderOffset = UDim.new(0, 0)
		Circle.OuterStroke.BorderOffset = UDim.new(0, 0)
		Effects:Tween(Circle.OuterStroke, { 0.6, 'Back' }, {BorderOffset = UDim.new(0.55, 0)})
		Effects:Tween(Circle.OuterCircle, { 0.6, 'Back' }, {BorderOffset = UDim.new(0.4, 0)})

		LockOnEffect.Parent = p_LookAtPart;
	end
end

function Camera:UseFov(p_Usage_Time: number, p_Value: number, p_Tween_Time: number?)
	if Camera.__Using_fov then
		return
	end

	Camera.__Using_fov = true;
	Effects:Tween(workspace.CurrentCamera, {p_Tween_Time or 0.25, 'Quad'}, {FieldOfView = p_Value})

	task.delay(p_Usage_Time, function()
		Camera.__Using_fov = false;
	end)
end

function Camera:Update(delta: number)
	local CameraObject = workspace.CurrentCamera
	CameraObject.CameraType = Enum.CameraType.Scriptable

	if not(Camera.__Subject) or (Camera:GetCurrentUser() ~= nil) then
		return
	end

	local Model = Camera.__Subject
	if not Camera.__Focused then
		return
	end

	local CameraRotation = CFrame.Angles(0, -Camera.__Rotation.X, 0) * CFrame.Angles(-Camera.__Rotation.Y, 0, 0)
	local CameraPosition;

	if not (Model:FindFirstChild('UpperTorso')) and not (Model:FindFirstChild('Torso')) then
		return
	end

	Camera.__Current_Zoom = math.lerp(Camera.__Current_Zoom, Camera.__Zoom, delta * 12)

	local ZoomValue = Camera.__Current_Zoom
	local Torso: Vector3 = (Model:FindFirstChild('UpperTorso') or Model:FindFirstChild('Torso')).Position
	local Root: Vector3 = Model:FindFirstChild('HumanoidRootPart').Position + Vector3.yAxis*2
	local Goal = Vector3.new(Torso.X, Torso:Lerp(Root, 0).Y, Torso.Z)
	local LookAtPart = Camera.__LookAtPart

	if Camera.__Moving_Delta.Magnitude > 0 and LookAtPart == nil then
		local IsConsole = Inputs:GetDevice() == GameEnum.Device.Console

		Camera.__Rotation += Camera.__Moving_Delta*Rad(Settings.Sensitivity)*(IsConsole and Settings.ConsoleSensitivity or 1)
		Camera.__Rotation = Vector2.new(Camera.__Rotation.X, Clamp(Camera.__Rotation.Y, Rad(Settings.Min_Angle), Rad(Settings.Max_Angle)))
	end

	--

	CameraPosition = Goal + Settings.Offset

	Camera.__Position = Camera.__Position:Lerp(CameraPosition, delta * Camera.__Delta)

	local SubCamOffset = CFrame.new()
	local Factor = 45;
	local CameraCFrame: CFrame = nil;
	if LookAtPart ~= nil then
		SubCamOffset = CFrame.new(4.5, 0, 0)
		CameraCFrame = CFrame.lookAt(Camera.__Position, LookAtPart.Position) * SubCamOffset;
		CameraCFrame = CFrame.lookAt(CameraCFrame.Position, LookAtPart.Position) * CFrame.new(0, 0, ZoomValue * 0.5)

		Factor = 15
		
		local Pitch, Yaw = CameraCFrame:ToOrientation()
		Camera.__Rotation = Vector2.new(-Yaw, -Pitch)
	else
		CameraCFrame = CFrame.lookAlong(Camera.__Position, CameraRotation.LookVector) * CFrame.new(0, 0, ZoomValue)
	end

	local Cast = workspace:Raycast(Camera.__Position, CameraCFrame.LookVector * -ZoomValue, World:GetMapParams(false, {}) :: RaycastParams)
	if Cast then
		CameraCFrame = CFrame.lookAlong(Cast.Position, CameraCFrame.LookVector) * SubCamOffset
	end

	if not Camera.__Using_fov then
		local Value = LookAtPart and 75 or 70
		CameraObject.FieldOfView = Value
	end
	CameraObject.CFrame = CameraObject.CFrame:Lerp(CameraCFrame, delta * Factor)

	--[[
	---
	local EndCf = CameraObject.CFrame
	local Length = (EndCf.Position - Camera.__Position).Magnitude;
	local Origin = CFrame.lookAt(EndCf.Position, Camera.__Position)
	local HalfFovCos = math.cos(math.rad(CameraObject.FieldOfView * 0.5))

	local HitColliders = workspace:GetPartBoundsInBox(Origin * CFrame.new(0, 0, -Length * 0.25), vector.create(15, 5, 4), Camera.__Enemy_Params)
	local Checked = {}
	for _, Collider in HitColliders do
		local Enemy = Enemies:GetFromCollider(Collider)
		if Enemy == nil then
			continue
		end

		local IsInGroup = table.find(Camera.__Enemies_Blocking_Vision, Enemy)

		Checked[Enemy:GetId()] = true

		local ToCollider = (Collider.Position - Origin.Position).Unit
		local DotResult = vector.dot(Origin.LookVector :: vector, ToCollider :: vector)

		local IsInFov = DotResult >= HalfFovCos
		if not IsInFov then
			if IsInGroup then
				Enemy:SetVisible(true)
			end

			continue
		elseif IsInGroup then continue end

		table.insert(Camera.__Enemies_Blocking_Vision, Enemy)
		Enemy:SetVisible(false)
	end

	for idx = #Camera.__Enemies_Blocking_Vision, 1, -1 do
		local Enemy = Camera.__Enemies_Blocking_Vision[idx]
		if Checked[Enemy:GetId()] then
			continue
		end

		Enemy:SetVisible(true)
		table.remove(Camera.__Enemies_Blocking_Vision, idx)
	end]]
end

function Camera:TweenTo(GoalCFrame: CFrame, Info: {number | string}?): Tween?
	local CameraObject = workspace.CurrentCamera

	if Info == nil then
		CameraObject.CFrame = GoalCFrame

		return;
	end

	return Effects:Tween(CameraObject, Info, {CFrame = GoalCFrame})
end

function Camera:GetCurrentUser(): string?
	return self.__UsedBy
end

function Camera:GetPivot(): CFrame
	return workspace.CurrentCamera.CFrame
end

function Camera:HorizontalVector(): vector
	return workspace.CurrentCamera.CFrame.LookVector * vector.create(1, 0, 1)
end


function Camera:MarkUsage(Key: string)
	if Camera.__UsedBy then
		return
	end

	Camera.__UsedBy = Key
end

function Camera:FreeUsage()
	Camera.__UsedBy = nil
end

return Camera
