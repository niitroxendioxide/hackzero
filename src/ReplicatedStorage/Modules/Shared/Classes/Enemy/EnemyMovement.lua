--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local World = require(Shared.World)

--
local DEBUG_ENEMY_POSITIONS = false

--
local EnemyMovement = {}
EnemyMovement.__index = EnemyMovement

function EnemyMovement.new(At: Vector3, Speed: number)
	local self = setmetatable({}, EnemyMovement)
	self.__Position = At or Vector3.zero
	self.__Looking = Vector3.zAxis
	self.__Direction = Vector3.zero
	self.__Target = nil
	self.__Speed = Speed or 6
	self.__Moved_in_last_step = false
	self.__Velocities = {}
	
	self:CreateCollider()

	return self
end

function EnemyMovement:CreateCollider()
	self.__Collider = Instance.new('Part')
	self.__Collider.CFrame = CFrame.new(self.__Position)
	self.__Collider.Size = Vector3.new(4, 5, 4)
	self.__Collider.Color = RunService:IsServer() and Color3.new(1) or Color3.new(0, 1)
	self.__Collider.CanCollide = false
	self.__Collider.Anchored = true
	self.__Collider.Transparency = (RunService:IsClient() and not DEBUG_ENEMY_POSITIONS) and 1 or 0.85
	self.__Collider.Parent = RunService:IsClient() and  workspace.World.Entities.Hitboxes or workspace.Camera.Enemies
	
	if DEBUG_ENEMY_POSITIONS and RunService:IsServer() then
		self.__debug_collider = Instance.new('Part')
		self.__debug_collider.CFrame = CFrame.new(self.__Position)
		self.__debug_collider.Size = Vector3.new(2, 7, 2)
		self.__debug_collider.Color = Color3.new(1, 1, 0)
		self.__debug_collider.CanCollide = false
		self.__debug_collider.Anchored = true
		self.__debug_collider.Parent = workspace
	end
	
	self.__Enemy_Collider = Instance.new('Part')
	self.__Enemy_Collider.CFrame = CFrame.new(self.__Position)
	self.__Enemy_Collider.Size = Vector3.new(4, 5, 2)
	self.__Enemy_Collider.Color = Color3.new(0, 0, 1)
	self.__Enemy_Collider.CanCollide = false
	self.__Enemy_Collider.Anchored = false
	self.__Enemy_Collider.Transparency = 1
	self.__Enemy_Collider.Parent = RunService:IsClient() and workspace.World.Entities.Colliders or workspace.Camera.Enemy_Collisions

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

function EnemyMovement:Knockback(Velocity: Vector3, Time: number?)
	local RayResult = workspace:Raycast(self:GetPivot().Position, Velocity * Time * 2, World:GetMapParams())

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
	local Movement = (ConvertedDirection * self.__Speed + Velocity) * Delta * World:GetSpeed()
	
	local Map = World:GetMapParams()
	local Colliders = World:GetColliderParams()
	
	local Collision = workspace:Spherecast(self.__Position, 1.5, ConvertedDirection * 2, Map)
	if Collision then
		local ProjectedMovement = Movement - Movement:Dot(Collision.Normal) * Collision.Normal

		Movement = ProjectedMovement * self.__Speed * Delta * World:GetSpeed()
	end
	
	local EntitiesHit = workspace:Spherecast(self.__Position, 1.5, ConvertedDirection * 2, Colliders)
	if EntitiesHit then
		local ProjectedMovement = Movement - Movement:Dot(EntitiesHit.Normal) * EntitiesHit.Normal

		Movement = ProjectedMovement * self.__Speed * Delta * World:GetSpeed()
	end

	self.__Moved_in_last_step = EntitiesHit == nil

	--
	self.__Position += Movement

	local Cast = workspace:Raycast(self.__Position, Vector3.yAxis * -100, World:GetMapParams())
	if Cast then
		self.__Position = Cast.Position + Vector3.yAxis * 3.15
	end
	
	if self.__Collider then
		self.__Collider.CFrame = CFrame.lookAlong(self.__Position, self.__Looking)
	end
	
	if self.__Collider and self.__debug_collider then
		self.__debug_collider.CFrame = self.__Collider.CFrame
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
