local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Modules.Shared

local World = require(Shared.World)
local PhysicsHelper = {}

function PhysicsHelper:CalculateCharacterCollisions(Origin: CFrame, MovementDir: Vector3, Delta: number, Blocks: {}): RaycastResult?
    local hasResult = nil
	local SideCount = 8
	local Wide = math.rad(130)
	local Params = World:GetCollisionParams(nil, Blocks) :: RaycastParams
	for i = -1.5, 1.5, 1.5 do
		for x = 0, SideCount do
			local OriginPoint = (Origin * CFrame.new(0, i, 0))
			local Angle = -(Wide * 0.5) + (Wide / SideCount) * x
			local Length = 4 + MovementDir.Magnitude * 0.1 * Delta * 4
			local Direction = (CFrame.lookAlong(OriginPoint.Position, MovementDir) * CFrame.Angles(0, Angle, 0)).LookVector * Length
			local Result = workspace:Raycast(OriginPoint.Position, Direction, Params)

			if (workspace:GetAttribute("DebugMovement") and RunService:IsServer() and RunService:IsStudio()) then
				local Part = Instance.new("Part")
				Part.Color = Result and Color3.new(0, 1) or Color3.new(1)
				Part.Anchored = true
				Part.CanCollide = false
				Part.CanQuery = false
				Part.Shape = Enum.PartType.Block
				Part.Size = Vector3.new(0.1, 0.1, Length)
				Part.CFrame = CFrame.lookAlong(OriginPoint.Position, Direction.Unit) * CFrame.new(0, 0, -Length/2)
				Part.Parent = workspace.World.Effects

				task.delay(Delta * 2, Part.Destroy, Part)
			end

			if Result then
				hasResult = Result
			end
		end
	end

	return hasResult;
end

return PhysicsHelper
