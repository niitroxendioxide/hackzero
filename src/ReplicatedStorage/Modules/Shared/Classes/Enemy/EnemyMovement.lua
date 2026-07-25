local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Shared = ReplicatedStorage.Modules.Shared
local PhysicsHelper = require(ReplicatedStorage.Modules.Shared.Libraries.PhysicsHelper)
local World = require(Shared.World)
local WorldFolder = workspace:FindFirstChild("World")

--
local DEBUG_ENEMY_POSITIONS = false

--
local EnemyMovement = {}
EnemyMovement.__index = EnemyMovement

function EnemyMovement.new(At: Vector3, Speed: number?, Height: number?)
	local self = setmetatable({}, EnemyMovement)
	self.__Position = At or Vector3.zero
	self.__Looking = Vector3.zAxis
	self.__Direction = Vector3.zero
	self.__Target = nil
	self.__Height = Height or 3.15
	self.__Speed = Speed or 6
	self.__Original_Speed = self.__Speed
	self.__World_Speed = 1
	self.__Moved_in_last_step = false
	self.__Velocities = {}
	self.__Speed_Change_Thread = nil
	self.__Walk_Speed_Thread = nil
	self.__Grab_Origin = nil
	self.__Grab_Offset = CFrame.new();

	self:CreateCollider()

	return self
end

function EnemyMovement:SetWalkSpeed(Speed: number, ForTime: number)
	if self.__Walk_Speed_Thread then
		task.cancel(self.__Walk_Speed_Thread)
	end

	self.__Speed = Speed

	self.__Walk_Speed_Thread = task.delay(ForTime, function()
		self.__Speed = self.__Original_Speed
		self.__Walk_Speed_Thread = nil;
	end)
end

function EnemyMovement:SetWorldSpeed(Speed: number, Time: number?)
	if self.__Speed_Change_Thread then
		task.cancel(self.__Speed_Change_Thread)
	end

	self.__World_Speed = Speed

	if not Time then return end
	self.__Speed_Change_Thread = task.delay(Time, function()
		self.__World_Speed = 1
	end)
end

function EnemyMovement:SetFollowPart(BasePart: BasePart, Offset: CFrame?)
	self.__Grab_Origin = BasePart;
	self.__Grab_Offset = Offset or CFrame.new();

	---
	local CollisionState = (BasePart == nil)

	self.__Enemy_Collider.CanQuery = CollisionState
	self.__Enemy_Collider.CanTouch = CollisionState
end

function EnemyMovement:CreateCollider()
	self.__Collider = Instance.new('Part')
	self.__Collider.CFrame = CFrame.new(self.__Position)
	self.__Collider.Size = Vector3.new(6, 4, 4)
	self.__Collider.Color = RunService:IsServer() and Color3.new(1) or Color3.new(0, 1)
	self.__Collider.CanCollide = false
	self.__Collider.Anchored = true
	self.__Collider.Shape = Enum.PartType.Cylinder
	self.__Collider.Transparency = (RunService:IsClient() and not DEBUG_ENEMY_POSITIONS) and 1 or 0.85
	self.__Collider.Parent = RunService:IsClient() and WorldFolder.Entities.Hitboxes or (workspace:FindFirstChild("Camera") :: Camera):FindFirstChild("Enemies")

	if DEBUG_ENEMY_POSITIONS and RunService:IsServer() then
		self.__debug_collider = Instance.new('Part')
		self.__debug_collider.CFrame = CFrame.new(self.__Position)
		self.__debug_collider.Size = Vector3.new(7, 1, 1)
		self.__debug_collider.Color = Color3.new(1, 0.172549, 0.172549)
		self.__debug_collider.CanCollide = false
		self.__debug_collider.Anchored = true
		self.__debug_collider.Shape = Enum.PartType.Cylinder
		self.__debug_collider.Parent = workspace
	end

	self.__Enemy_Collider = Instance.new('Part')
	self.__Enemy_Collider.CFrame = CFrame.new(self.__Position)-- * CFrame.Angles(0, 0, math.pi/2)
	self.__Enemy_Collider.Size = Vector3.new(6, 3, 3)
	self.__Enemy_Collider.Color = Color3.new(0, 0, 1)
	self.__Enemy_Collider.CanCollide = false
	self.__Enemy_Collider.Anchored = false
	self.__Enemy_Collider.Shape = Enum.PartType.Cylinder
	self.__Enemy_Collider.Transparency = 1
	self.__Enemy_Collider.Parent = RunService:IsClient() and WorldFolder.Entities.Colliders or (workspace:FindFirstChild("Camera") :: Camera):FindFirstChild("Enemy_Collisions")

	local Weld = Instance.new('WeldConstraint')
	Weld.Part0 = self.__Enemy_Collider
	Weld.Part1 = self.__Collider
	Weld.Parent = self.__Enemy_Collider
end

function EnemyMovement:GetHitbox()
	return self.__Collider
end

function EnemyMovement:Move(Direction: Vector3)
	self.__Direction = Direction
end

function EnemyMovement:GetPivot()
	return CFrame.lookAlong(self.__Position, self.__Looking, Vector3.yAxis)
end

function EnemyMovement:Rotate(TargetPosition: Vector3)
	self.__Looking = CFrame.lookAt(self.__Position, TargetPosition).LookVector * Vector3.new(1, 0, 1)
end

function EnemyMovement:Knockback(Velocity: Vector3, Time: number)
	local Direction = (Velocity * Time * 2) :: Vector3
	local RayResult = workspace:Raycast(self:GetPivot().Position, Direction, World:GetEntityMapParams(false) :: RaycastParams)

	if RayResult then
		return
	end

	--
	local Object; Object = {Velocity, Time, task.delay(Time, function()
		table.remove(self.__Velocities, table.find(self.__Velocities, Object))
	end)}

	table.insert(self.__Velocities, Object)

	return Object
end

function EnemyMovement:GetSumOfKnockbacks()
	local Total = Vector3.zero

	for _, Object in self.__Velocities do
		Total += Object[1]
	end

	return Total
end

function EnemyMovement:Update(Delta: number)
	local Position = self.__Position

	local Velocity = self:GetSumOfKnockbacks()

	local ConvertedDirection = CFrame.lookAlong(Position, self.__Looking):VectorToWorldSpace(self.__Direction)
	local Movement = (ConvertedDirection * self.__Speed + Velocity) * Delta * World:GetSpeed() * self.__World_Speed

	--local Map = World:GetEntityMapParams(false)
	if self.__Grab_Origin == nil then
		local Colliders = World:GetEnemyColliderParams()

		local Collision = PhysicsHelper:CalculateEnemyCollisions(self:GetPivot(), Movement, Delta)
		if Collision then
			local ProjectedMovement = Movement - Movement:Dot(Collision.Normal) * Collision.Normal

			Movement = ProjectedMovement * (self.__Speed * self.__World_Speed) * Delta * World:GetSpeed()
		end

		local EntitiesHit = workspace:Spherecast(self.__Position, 1.5, ConvertedDirection * 2, Colliders)
		if EntitiesHit then
			local ProjectedMovement = Movement - Movement:Dot(EntitiesHit.Normal) * EntitiesHit.Normal

			Movement = ProjectedMovement * (self.__Speed * self.__World_Speed) * Delta * World:GetSpeed()
		end

		self.__Moved_in_last_step = EntitiesHit == nil

		self.__Position += Movement

		local Cast = workspace:Raycast(self.__Position, Vector3.yAxis * -(self.__Height + 2.5), World:GetEntityMapParams(false) :: RaycastParams)
		if Cast then
			self.__Position = Cast.Position + Vector3.yAxis * self.__Height
		end
	else
		self.__Looking = (self.__Grab_Origin.CFrame * CFrame.Angles(0, math.pi, 0) * self.__Grab_Offset).LookVector;
		self.__Position = (self.__Grab_Origin.CFrame * self.__Grab_Offset).Position;
	end

	if self.__Collider then
		self.__Collider.CFrame = CFrame.lookAlong(self.__Position, self.__Looking) * CFrame.Angles(0, 0, math.pi/2)
	end

	if self.__Collider and self.__debug_collider then
		self.__debug_collider.CFrame = self.__Collider.CFrame
	end
end

function EnemyMovement:SnapToFirstGround()
	local Cast = workspace:Raycast(self.__Position, Vector3.yAxis * -500, World:GetEntityMapParams(false) :: RaycastParams)
	if Cast then
		self.__Position = Cast.Position + Vector3.yAxis * self.__Height
	end
end

function EnemyMovement:MovementInLastStep()
	return self.__Moved_in_last_step
end

function EnemyMovement:PivotTo(Pivot: CFrame)
	
	self.__Position = Pivot.Position
	self.__Looking = Pivot.LookVector
	
end

function EnemyMovement:Destroy()
	if self.__Collider then
		self.__Collider:Destroy()
	end
	
	if self.__debug_collider then
		self.__debug_collider:Destroy()
	end
	
	if self.__Enemy_Collider then
		self.__Enemy_Collider:Destroy()
	end
	
end

return EnemyMovement
