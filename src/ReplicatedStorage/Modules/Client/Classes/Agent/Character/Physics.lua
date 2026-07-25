--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Shared = ReplicatedStorage.Modules.Shared

local PhysicsHelper = require(Shared.Libraries.PhysicsHelper)
local World = require(Shared.World)
local Types = require(Shared.Types)
--local Signal = require(Shared.Utility.Signal)

--
local PhysicsClass = {} :: {[string]: (self: Types.PhysicsController, any) -> any, new: () -> Types.PhysicsController}
PhysicsClass.__index = PhysicsClass

function PhysicsClass.new(States: Types.StatesClass, Height: number, debug_t: boolean?): Types.PhysicsController
	local WorldSpawn = workspace:WaitForChild('SpawnLocation') :: BasePart

	local self = setmetatable({}, PhysicsClass)
	self.__States = States
	self.__Debug = debug_t
	self.__Height = Height or 3.15
	self.__Normal = Vector3.yAxis
	self.__Position = WorldSpawn.Position + Vector3.new(0, self.__Height, 0)
	self.__Rotation = Vector3.zAxis
	self.__DelayedPosition = self.__Position
	self.__RotationGoal = Vector3.zAxis

	self.__MovementVelocity = 0
	self.__SurfaceVelocity = Vector3.zero
	self.__LastMovementVelocity = Vector3.zero
	self.__Velocity = Vector3.zero
	self.__ActiveThread = nil
	self.__PhysicsSpeed = 1
	self.__Moving = false
	self.__Active = false
	self.__MovementAcceleration = 0
	self.__Linear_Movements = {}
	self.__Forward_Velocities = {}
	self.__Added_Colliders = {}

	-- >>

	return self
end

function PhysicsClass:Run()
	if self.__ActiveThread then
		if not self.__Active then
			self.__Active = true
		end

		return
	end


	self:CreateCollider()

	self.__Active = true
	self.__ActiveThread = RunService.PreRender:Connect(function(Delta: number)
		if self.__Debug then

		end

		if not self.__Active then
			return
		end

		self:Update(Delta)
	end)
end

function PhysicsClass.SetColliderGroupState(self: Types.PhysicsController, Group: {}, State: boolean?)
	if State ~= true then
		State = nil
	end

	self.__Added_Colliders[Group] = State
end

function PhysicsClass:Pause()
	self.__Active = false
end

function PhysicsClass:Resume()
	self.__Active = true
end

function PhysicsClass:Rotate(Angle: Vector3, Instant: boolean?)
	if Instant then
		self.__Rotation = Angle
	end

	self.__RotationGoal = Angle
end

function PhysicsClass:ApplyForwardImpulse(Power: number, FadeOutTime: number, Linear: boolean?)
	local Object = {self.__Rotation * Power, Power, FadeOutTime, os.clock(), Linear}
	table.insert(self.__Forward_Velocities, Object)

	return Object
end

function PhysicsClass:RemoveForwardImpulse(Obj: {})
	local Index = table.find(self.__Forward_Velocities, Obj)
	if Index then
		table.remove(self.__Forward_Velocities, Index)
	end
end

function PhysicsClass:GetPivot()
	return CFrame.lookAlong(self.__Position, self.__Rotation, Vector3.yAxis)
end

function PhysicsClass:PivotTo(To: CFrame)
	assert(typeof(To) == 'CFrame', 'Not a CFrame')

	self.__Normal = To.UpVector
	self.__Position = To.Position
	self.__Rotation = To.LookVector
	self.__RotationGoal = To.LookVector
end

function PhysicsClass:SetMovementVelocity(Velocity: number)
	if self.__Moving == false then
		self.__MovementAcceleration = 0
	end

	self.__Moving = true
	self.__MovementVelocity = Velocity
end

function PhysicsClass:GetAdditionalVelocities()
	local Total = Vector3.zero

	for _, Object in self.__Linear_Movements do
		Total += Object[1]
	end

	for _, Object in self.__Forward_Velocities do
		Total += Object[1]
	end

	return Total
end


function PhysicsClass:AddLinearMovement(Velocity: Vector3, Time: number)
	local Object; Object = {Velocity, Time, task.delay(Time, function()
		table.remove(self.__Linear_Movements, table.find(self.__Linear_Movements, Object))
	end)}

	table.insert(self.__Linear_Movements, Object)

	return Object
end

function PhysicsClass:StopMovement()
	if self.__Moving == true then
		local NewVelocity =  (self.__MovementVelocity) * self.__Rotation.Unit

		if self.__LastMovementVelocity:Dot(NewVelocity.Unit) < 0 then
			NewVelocity += self.__LastMovementVelocity
		end

		self.__LastMovementVelocity = NewVelocity
		self.__MovementAcceleration = 0
		self.__MovementVelocity = 0
	end

	self.__Moving = false
end

function PhysicsClass:ApplyImpulse(Velocity: Vector3)
	self.__Velocity += Velocity
end

function PhysicsClass:CalculateVelocityDeceleration(Velocity: Vector3, AirMod: number)
	AirMod = AirMod or 1

	local AirFriction = World:GetAirFriction()
	local SurfaceFriction = World:GetSurfaceFriction(self.__Position)

	return ((Velocity * (AirFriction * AirMod)) + (Velocity * SurfaceFriction)) * SurfaceFriction
end

function PhysicsClass:Update(Delta: number)
	local TotalSpeedDeceleration =  self:CalculateVelocityDeceleration(self.__Velocity, .5)
	--local MovementSpeedDeceleration = self:CalculateVelocityDeceleration(self.__MovementVelocity)
	local Collider = self:GetCollider()

	local CurrentWorldSpeed = World:GetSpeed()

	self.__MovementAcceleration = math.clamp(self.__MovementAcceleration + Delta * World.CharacterAcceleration, 0, 1)

	for _, Object in self.__Forward_Velocities do
		local Timepassed = (os.clock() - Object[4])
		if Timepassed > Object[3] then
			self:RemoveForwardImpulse(Object)
			continue
		end

		local NewValue = Object[2] - Object[2] * (Timepassed / Object[3])
		if Object[5] == true then
			NewValue = Object[2]
		end

		Object[1] = self.__Rotation.Unit * NewValue
	end

	local MovementVelocity = (self.__MovementVelocity * self.__MovementAcceleration * self.__Rotation.Unit * self.__States:GetVelocityMod())
	self.__LastMovementVelocity -= self:CalculateVelocityDeceleration(self.__LastMovementVelocity, 3) * CurrentWorldSpeed * Delta
	self.__Velocity -= TotalSpeedDeceleration * CurrentWorldSpeed * Delta
	self.__Rotation = self.__Rotation:Lerp(self.__RotationGoal, 1) --Delta * 24


	local AddOns = self:GetAdditionalVelocities()
	local Velocity = self.__Velocity + AddOns

	--
	local Origin = self:GetPivot() * CFrame.new(0, 0, Collider.Size.Z/2)
	local EnemyCollisions = workspace:Spherecast(Origin.Position, 1.75, Origin.LookVector * 3, World:GetEnemyColliderParams() :: RaycastParams)
	if EnemyCollisions then
		Velocity = Vector3.zero
	end

	-- Movement
	local TotalDisplacement =  MovementVelocity + Velocity + self.__SurfaceVelocity + self.__LastMovementVelocity

	if TotalDisplacement.Magnitude > .1 then
		local Moved = (TotalDisplacement * CurrentWorldSpeed * Delta)

		local AddedColliderParams = World:GetMapParams(false, self.__Added_Colliders):: RaycastParams
		local Extra = math.atan(self.__Normal:Dot(Vector3.yAxis)) + World.StepHeight
		local HeightExtra = self.__Height + Extra
		local CanReachFloor = workspace:Raycast(self.__Position + Moved, Vector3.yAxis * -HeightExtra, AddedColliderParams)
		local Collision = PhysicsHelper:CalculateCharacterCollisions(Origin, TotalDisplacement, Delta, self.__Added_Colliders)
		local NoCollide = (not Collision or Collision.Normal:Dot(Vector3.new(0, 1, 0)) > 0.1)

		if CanReachFloor and (CanReachFloor.Position.Y - (self.__Position.Y - self.__Height)) < World.StepHeight then
			if NoCollide then
				self.__Position += Moved
			elseif Collision then
				local ProjectedMovement = TotalDisplacement - TotalDisplacement:Dot(Collision.Normal) * Collision.Normal

				local Params = World:GetCollisionParams(nil, self.__Added_Colliders) :: RaycastParams
				local Result = workspace:Raycast(Origin.Position, ProjectedMovement.Unit * 3, Params)--workspace:Spherecast(Origin.Position, 1, Direction, Params)
				if not Result then
					self.__Position += ProjectedMovement * CurrentWorldSpeed * Delta
				end
			end
		elseif not CanReachFloor then 
			local Projected = PhysicsHelper:CalculateDirectionFromVoid(Moved, self.__Position, HeightExtra, AddedColliderParams) * Moved.Magnitude
			local NewCheck = workspace:Raycast(self.__Position + Projected, Vector3.yAxis * -(HeightExtra), AddedColliderParams)
			if NewCheck then
				if NoCollide then
					self.__Position += Projected
				else
					local ProjectedMovement = Projected - Projected:Dot(Collision.Normal) * Collision.Normal

					local Params = World:GetCollisionParams(nil, self.__Added_Colliders) :: RaycastParams
					local Result = workspace:Raycast(Origin.Position, ProjectedMovement.Unit * 3, Params)
					if not Result then
						self.__Position += ProjectedMovement * CurrentWorldSpeed * Delta
					end
				end
			end
		end
	end

	local Cast = workspace:Raycast(self:GetPivot().Position, Vector3.yAxis * -100, World:GetMapParams(false, self.__Added_Colliders) :: RaycastParams)
	if Cast then
		self.__Normal = Cast.Normal
		self.__SurfaceVelocity = Cast.Instance.AssemblyLinearVelocity
		self.__Position = Vector3.new(self.__Position.X, Cast.Position.Y + self.__Height, self.__Position.Z)
	end

	self.__Collider:PivotTo(self:GetPivot())
end

--
function PhysicsClass:CreateCollider()
	if self.__Collider then
		self.__Collider:Destroy()
	end

	local WorldFolder = workspace:FindFirstChild('World') :: Folder
	local Collider = Instance.new('Part')
	Collider.Size = Vector3.new(4, self.__Height * 1.5873015873, 3)
	Collider.Transparency = 1
	Collider.Color = Color3.new(1)
	Collider.Anchored = true
	Collider.CanCollide = false
	Collider.Position = self.__Position
	Collider.Parent = WorldFolder.Entities.Hitboxes

	self.__Collider = Collider
end

function PhysicsClass:GetCollider(): BasePart
	return self.__Collider
end

function PhysicsClass:Destroy(): ()
	local Collider = self.__Collider

	if Collider then
		Collider:Destroy()
	end

	if self.__ActiveThread then
		self.__ActiveThread:Disconnect()
	end
end

return PhysicsClass
