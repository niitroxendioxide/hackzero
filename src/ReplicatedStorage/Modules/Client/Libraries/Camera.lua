--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local Shared = ReplicatedStorage.Modules.Shared
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
}

function Camera:RotateTo(GivenCFrame: CFrame)
	local Yaw, Pitch = GivenCFrame:ToOrientation()

	Camera.__Position = GivenCFrame.Position
	Camera.__Rotation = Vector2.new(Yaw, Pitch)
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

		local MouseDelta = UserInputService:GetMouseDelta()

		Camera.__Rotation += MouseDelta*Rad(Settings.Sensitivity)
		Camera.__Rotation = Vector2.new(Camera.__Rotation.X, Clamp(Camera.__Rotation.Y, Rad(Settings.Min_Angle), Rad(Settings.Max_Angle)))
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

function Camera:Update(delta: number)
	if not(Camera.__Subject) or Camera.__UsedBy then
		return
	end

	local Model = Camera.__Subject
	if not Camera.__Focused then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

		return
	end

	local CameraObject = workspace.CurrentCamera
	local CameraRotation = CFrame.Angles(0, -Camera.__Rotation.X, 0) * CFrame.Angles(-Camera.__Rotation.Y, 0, 0)
	local CameraPosition;

	local Torso: Vector3 = (Model:FindFirstChild('UpperTorso') or Model:FindFirstChild('Torso')).Position
	local Root: Vector3 = Model:FindFirstChild('HumanoidRootPart').Position + Vector3.yAxis*2
	local Goal = Vector3.new(Root.X, Torso:Lerp(Root, 0.5).Y, Root.Z)

	print(Goal.Y)

	CameraPosition = Goal + Settings.Offset

	Camera.__Position = Camera.__Position:Lerp(CameraPosition, delta * 24)

	local CameraCFrame = CFrame.lookAlong(Camera.__Position, CameraRotation.LookVector) * CFrame.new(0, 0, Camera.__Zoom)

	local Cast = workspace:Raycast(Camera.__Position, CameraRotation.LookVector * -Camera.__Zoom, World:GetMapParams(false, {}) :: RaycastParams)
	if Cast then
		CameraCFrame = CFrame.lookAlong(Cast.Position, CameraRotation.LookVector)
	end

	CameraObject.FieldOfView = 70
	CameraObject.CameraType = Enum.CameraType.Scriptable
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
