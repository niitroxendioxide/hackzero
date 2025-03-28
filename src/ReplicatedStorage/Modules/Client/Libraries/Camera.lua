--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local Shared = ReplicatedStorage.Modules.Shared
local World = require(Shared.World)

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
	__Zoom = 15,
	__Subject = nil,
	__Inited = false,
}

function Camera:Init()
	if Camera.__Inited then
		return
	end
	
	Camera.__Inited = true
	
	UserInputService.TouchRotate:Connect(function(touchPositions: {any}, rotation: number, velocity: number, state: Enum.UserInputState, gameProcessedEvent: boolean) 
		
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

function Camera:SetSubject(Target: Model)
	assert(typeof(Target) == 'Instance' and Target:IsA('Model'), 'Cannot set subject to a non-model')
	
	self.__Subject = Target
end

function Camera:Update(delta: number)
	if not Camera.__Subject then
		return
	end
	
	local Model = Camera.__Subject
	
	local CameraObject = workspace.CurrentCamera
	local CameraRotation = CFrame.Angles(0, -Camera.__Rotation.X, 0) * CFrame.Angles(-Camera.__Rotation.Y, 0, 0)
	local CameraPosition = Model:FindFirstChild('Head').Position + Settings.Offset
	
	Camera.__Position = Camera.__Position:Lerp(CameraPosition, delta * 14)
	
	local CameraCFrame = CFrame.lookAlong(Camera.__Position, CameraRotation.LookVector) * CFrame.new(0, 0, Camera.__Zoom)
	
	local Cast = workspace:Raycast(Camera.__Position, CameraRotation.LookVector * -Camera.__Zoom, World:GetMapParams())
	if Cast then
		CameraCFrame = CFrame.lookAlong(Cast.Position, CameraRotation.LookVector)
	end
	
	CameraObject.CameraType = Enum.CameraType.Scriptable
	CameraObject.CFrame = CameraObject.CFrame:Lerp(CameraCFrame, delta * 45)
end

return Camera
