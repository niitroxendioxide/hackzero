local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Modules.Shared

local World = require(Shared.World)
local Env = require(Shared.Environment)
local PhysicsHelper = {}

local ENEMY_SIZE_RADIUS = 2.25

function PhysicsHelper:CalculateCharacterCollisions(Origin: CFrame, MovementDir: Vector3, Delta: number, Blocks: {}): RaycastResult?
    local hasResult = nil
	local SideCount = 8
	local Wide = math.rad(90)
	local Params = World:GetCollisionParams(nil, Blocks) :: RaycastParams
	for i = -1.5, 1.5, 1.5 do
		for x = 0, SideCount do
			local OriginPoint = (Origin * CFrame.new(0, i, 0))
			local Angle = -(Wide * 0.5) + (Wide / SideCount) * x
			local Length = 4 + MovementDir.Magnitude * 0.1 * Delta * 4
			local Direction = (CFrame.lookAlong(OriginPoint.Position, MovementDir) * CFrame.Angles(0, Angle, 0)).LookVector * Length
			local Result = workspace:Raycast(OriginPoint.Position, Direction, Params)

			if (Env.PROJECT_COLLISIONS and RunService:IsClient()() and RunService:IsStudio()) then
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

function PhysicsHelper:GetSquareExitNormal(p_Direction: vector): vector
    local AbsX, AbsZ = math.abs(p_Direction.x), math.abs(p_Direction.z)

    if AbsX > AbsZ then
        return vector.create(p_Direction.x >= 0 and 1 or -1, 0, 0)
    elseif AbsZ > AbsX then
        return vector.create(0, 0, p_Direction.z >= 0 and 1 or -1)
    end

    return vector.create(p_Direction.x >= 0 and 1 or -1, 0, 0)
end

function PhysicsHelper:CalculateDirectionFromVoid(p_Direction: vector, p_At: vector, p_Height: number, p_Params: RaycastParams?): vector
    local Forward = vector.normalize(p_Direction)
    local Normal = -Forward

    local Cross = vector.normalize(vector.cross(Normal, vector.create(0, 1, 0)))
    local Inverse = -Cross

    local Down = vector.create(0, -p_Height, 0)
    local LHit = workspace:Raycast(p_At + Cross, Down, p_Params)
    local RHit = workspace:Raycast(p_At + Inverse, Down, p_Params)

    if LHit and not RHit then
        return Cross
    elseif RHit and not LHit then
        return Inverse
    elseif LHit and RHit then
        return (LHit.Distance <= RHit.Distance) and Cross or Inverse
    end
	
    return Cross
end

function PhysicsHelper:CalculateEnemyCollisions(Origin: CFrame, MovementDir: Vector3, Delta: number): RaycastResult?
    local hasResult = nil
	local MapParams = World:GetEntityMapParams(false)
	if MovementDir.Magnitude <= 0 then
		return
	end

	local DebugOn = (workspace:GetAttribute("DebugMovement") and RunService:IsClient() and RunService:IsStudio())
	for i = 0, 1.5, 1.5 do
		local OriginPoint = (Origin * CFrame.new(0, i, 0))
		local Length = 2 + MovementDir.Magnitude * 0.1 * Delta * 4
		local Direction = (CFrame.lookAlong(OriginPoint.Position, MovementDir)).LookVector * Length

		local Result = workspace:Spherecast(OriginPoint.Position, ENEMY_SIZE_RADIUS, Direction, MapParams)

		if DebugOn then
			local Part = Instance.new("Part")
			Part.Color = Result and Color3.new(0, 1) or Color3.new(1)
			Part.Anchored = true
			Part.CanCollide = false
			Part.CanQuery = false
			Part.Shape = Enum.PartType.Ball
			Part.Size = Vector3.one * ENEMY_SIZE_RADIUS
			Part.CFrame = CFrame.lookAlong(OriginPoint.Position, Direction.Unit) * CFrame.new(0, 0, -Length/2)
			Part.Parent = workspace.World.Effects

			task.delay(Delta, Part.Destroy, Part)
		end

		if Result then
			hasResult = Result
		end
	end

	return hasResult;
end

return PhysicsHelper
