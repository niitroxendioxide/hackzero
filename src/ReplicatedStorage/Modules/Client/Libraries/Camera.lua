--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService('UserInputService')

local Shared = ReplicatedStorage.Modules.Shared
local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local World = require(Shared.World)
local Effects = require(Shared.Utility.Effects)

--
local Rad, Clamp = math.rad, math.clamp
local Settings = {
	Offset = Vector3.new(0, 2),

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
	__Track_Type = 1,
	__Subject = nil,
	__Inited = false,
	__UsedBy = nil,
	__Target_Part = "Head",
	__Focused = true,
	__Using_fov = false,
	__Delta = 24,
	__Delta_thread = nil,
	__Moving_Delta = Vector2.new(),
}

function Camera:RotateTo(GivenCFrame: CFrame)
	local Yaw, Pitch = GivenCFrame:ToOrientation()

	Camera.__Position = GivenCFrame.Position
	Camera.__Rotation = Vector2.new(Yaw, Pitch)
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
		if (Input.UserInputType == Enum.UserInputType.MouseMovement) then
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

function Camera:UseFov(p_Usage_Time: number)
	if Camera.__Using_fov then
		return
	end

	Camera.__Using_fov = true;

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


	local Torso: Vector3 = (Model:FindFirstChild('UpperTorso') or Model:FindFirstChild('Torso')).Position
	local Root: Vector3 = Model:FindFirstChild('HumanoidRootPart').Position + Vector3.yAxis*2
	local Goal = Vector3.new(Torso.X, Torso:Lerp(Root, 0).Y, Torso.Z)

	if Camera.__Moving_Delta.Magnitude > 0 then
		local IsConsole = Inputs:GetDevice() == GameEnum.Device.Console

		Camera.__Rotation += Camera.__Moving_Delta*Rad(Settings.Sensitivity)*(IsConsole and Settings.ConsoleSensitivity or 1)
		Camera.__Rotation = Vector2.new(Camera.__Rotation.X, Clamp(Camera.__Rotation.Y, Rad(Settings.Min_Angle), Rad(Settings.Max_Angle)))
	end

	--
	CameraPosition = Goal + Settings.Offset

	Camera.__Position = Camera.__Position:Lerp(CameraPosition, delta * Camera.__Delta)

	local CameraCFrame = CFrame.lookAlong(Camera.__Position, CameraRotation.LookVector) * CFrame.new(0, 0, Camera.__Zoom)
	--print(CameraCFrame.LookVector)

	local Cast = workspace:Raycast(Camera.__Position, CameraRotation.LookVector * -Camera.__Zoom, World:GetMapParams(false, {}) :: RaycastParams)
	if Cast then
		CameraCFrame = CFrame.lookAlong(Cast.Position, CameraRotation.LookVector)
	end

	if not Camera.__Using_fov then
		CameraObject.FieldOfView = 70
	end
	CameraObject.CFrame = CameraObject.CFrame:Lerp(CameraCFrame, delta * 45)
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
