--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--
local Shared = ReplicatedStorage.Modules.Shared

local PhysicsHelper = require(Shared.Libraries.PhysicsHelper)
local World = require(Shared.World)
local Types = require(Shared.Types.Agents)

local StatesClass = require(Shared.Classes.Agents.States)

-- DEBUG
local TestEnv = require("../../../.testenv/settings")
local REPLICATE_HITBOX = RunService:IsStudio() and TestEnv.REPLICATE_CONSTANTS.HITBOXES

--
local ServerCharacterClass = {}
ServerCharacterClass.__index = ServerCharacterClass
ServerCharacterClass.__tostring = function(self)
	return self.Name
end

function ServerCharacterClass.new(Name: string, Height: number): Types.ServerCharacterClass
	local Spawn = workspace:WaitForChild("SpawnLocation")
	local self = setmetatable({}, ServerCharacterClass)
	self.Name = Name
	self.States = StatesClass.new(Name)

	-- Privates
	self.__Height = Height or 3.15
	self.__Normal = Vector3.yAxis
	self.__Position = Spawn.Position + Vector3.new(0, self.__Height, 0)
	self.__Rotation = Vector3.zAxis

	self.__MovementVelocity = Vector3.zero
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

	return self
end

function ServerCharacterClass:Init()
	self.__Active = true

	if self.__ActiveThread == nil then
		self:CreateCollider()

		self.__ActiveThread = RunService.Stepped:Connect(function(_, Delta: number)
			if not self.__Active then
				return
			end

			self:Update(Delta)
		end)
	end
end

function ServerCharacterClass:SetColliderGroupState(Group: {}, State: boolean?)
	if State ~= true then
		State = nil
	end

	self.__Added_Colliders[Group] = State
end


function ServerCharacterClass:Move(_)
	if self.__Moving == false then
		self.__MovementAcceleration = 0
	end

	self.__Moving = true
end

function ServerCharacterClass:Stop()
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

function ServerCharacterClass:Rotate(Angle: Vector3)
	self.__Rotation = Angle
end

function ServerCharacterClass:GetPivot()
	return CFrame.lookAlong(self.__Position, self.__Rotation, Vector3.yAxis)
end

function ServerCharacterClass:PivotTo(To: CFrame)
	assert(typeof(To) == 'CFrame', 'Not a CFrame')

	self.__Normal = To.UpVector
	self.__Position = To.Position
	self.__Rotation = To.LookVector
end

function ServerCharacterClass:CalculateVelocityDeceleration(Velocity: Vector3, AirMod: number)
	AirMod = AirMod or 1

	local AirFriction = World:GetAirFriction()
	local SurfaceFriction = World:GetSurfaceFriction(self.__Position)

	return ((Velocity * (AirFriction * AirMod)) + (Velocity * SurfaceFriction)) * SurfaceFriction
end


function ServerCharacterClass:GetAdditionalVelocities()
	local Total = Vector3.zero

	for _, Object in self.__Linear_Movements do
		Total += Object[1]
	end

	for _, Object in self.__Forward_Velocities do
		Total += Object[1]
	end

	return Total
end

function ServerCharacterClass:ApplyForwardImpulse(Power: number, FadeOutTime: number, Linear: boolean?)
	local Object = {self.__Rotation * Power, Power, FadeOutTime, os.clock(), Linear}
	table.insert(self.__Forward_Velocities, Object)

	return Object
end

function ServerCharacterClass:RemoveForwardImpulse(Obj: {})
	local Index = table.find(self.__Forward_Velocities, Obj)
	if Index then
		table.remove(self.__Forward_Velocities, Index)
	end
end



function ServerCharacterClass:AddLinearMovement(Velocity: Vector3, Time: number)
	local Object; Object = {Velocity, Time, task.delay(Time, function()
		table.remove(self.__Linear_Movements, table.find(self.__Linear_Movements, Object))
	end)}

	table.insert(self.__Linear_Movements, Object)

	return Object
end

function ServerCharacterClass:GetTotalVelocity(): Vector3
	local MovementVelocity = (self.__MovementVelocity * self.__MovementAcceleration * self.__Rotation.Unit * self.States:GetVelocityMod())
	local Velocity = self.__Velocity + self:GetAdditionalVelocities()

	--
	return (MovementVelocity + Velocity + self.__SurfaceVelocity + self.__LastMovementVelocity)
end

function ServerCharacterClass:Update(Delta: number)
	local TotalSpeedDeceleration =  self:CalculateVelocityDeceleration(self.__Velocity, .5)
	local CurrentWorldSpeed = World:GetSpeed()

	self.__MovementAcceleration = math.clamp(self.__MovementAcceleration + Delta * World.CharacterAcceleration, 0, 1)

	if self.__Moving then
		self.__MovementVelocity = self.States:GetSpeed()
	end

	-- 1 dir, 2 power, 3 lifetime, 4 time, 5 linear?
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

	local MovementVelocity = (self.__MovementVelocity * self.__MovementAcceleration * self.__Rotation.Unit * self.States:GetVelocityMod())
	self.__LastMovementVelocity -= self:CalculateVelocityDeceleration(self.__LastMovementVelocity, 3) * CurrentWorldSpeed *Delta
	self.__Velocity -= TotalSpeedDeceleration * CurrentWorldSpeed * Delta

	local Velocity = self.__Velocity + self:GetAdditionalVelocities()

	local Origin = self:GetPivot() * CFrame.new(0, 0, 1.5)
	local EnemyCollisions = workspace:Spherecast(Origin.Position, 1.75, Origin.LookVector * 3, World:GetEnemyColliderParams() :: RaycastParams)
	if EnemyCollisions then
		Velocity = Vector3.zero
	end

	-- Movement
	local TotalDisplacement =  MovementVelocity + Velocity + self.__SurfaceVelocity + self.__LastMovementVelocity
	if TotalDisplacement.Magnitude > .1 then
		local Moved = (TotalDisplacement * CurrentWorldSpeed * Delta)

		local Extra = math.atan(self.__Normal:Dot(Vector3.yAxis)) + World.StepHeight
		local CanReachFloor = workspace:Raycast(self.__Position + Moved, Vector3.yAxis * -(self.__Height + Extra), World:GetMapParams(false, self.__Added_Colliders) :: RaycastParams)
		local Collision = PhysicsHelper:CalculateCharacterCollisions(Origin, TotalDisplacement, Delta, self.__Added_Colliders)

		if CanReachFloor and (CanReachFloor.Position.Y - (self.__Position.Y - self.__Height)) < World.StepHeight then
			if not Collision or Collision.Normal:Dot(Vector3.new(0, 1, 0)) > 0.1 then
				self.__Position += Moved
			elseif Collision then
				local ProjectedMovement = TotalDisplacement - TotalDisplacement:Dot(Collision.Normal) * Collision.Normal

				local Params = World:GetCollisionParams(nil, self.__Added_Colliders) :: RaycastParams
				local Result = workspace:Raycast(Origin.Position, ProjectedMovement.Unit * 3, Params)--workspace:Spherecast(Origin.Position, 1, Direction, Params)
				if not Result then
					self.__Position += ProjectedMovement * CurrentWorldSpeed * Delta
				end
			end
		end
	end

	local Cast = workspace:Raycast(self:GetPivot().Position, Vector3.yAxis * -100, World:GetMapParams(false, self.__Added_Colliders) :: RaycastParams)
	if Cast then
		self.__SurfaceVelocity = Cast.Instance.AssemblyLinearVelocity
		self.__Position = Vector3.new(self.__Position.X, Cast.Position.Y + self.__Height, self.__Position.Z)
	end

	if self.__Collider then
		self.__Collider:PivotTo(self:GetPivot())
	end
end

function ServerCharacterClass:ApplyImpulse(Velocity: Vector3)
	self.__Velocity += Velocity
end

function ServerCharacterClass:CreateCollider()
	if self.__Collider then
		self.__Collider:Destroy()
	end

	local WorldFolder = workspace:FindFirstChild("World")::Folder
	local Collider = Instance.new('Part')
	Collider.Size = Vector3.new(4, self.__Height * 1.5873015873, 3)
	Collider.Transparency = .85
	Collider.Color = Color3.new(0, 1)
	Collider.Name = self.Name .. 'Collider'
	Collider.Anchored = true
	Collider.CanCollide = false
	Collider.Position = self.__Position
	Collider.Parent = REPLICATE_HITBOX and WorldFolder.Entities.Hitboxes or workspace:FindFirstChildOfClass("Camera")

	self.__Collider = Collider
end

function ServerCharacterClass:IsMoving()
	return self.__Moving
end

function ServerCharacterClass:GetState()
	return self.States:GetState()
end

return ServerCharacterClass
