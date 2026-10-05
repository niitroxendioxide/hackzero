--[[
	@class RecruitMovement

	Kinematics of a recruit, shared by the server entity and its client copy so the client
	predicts with the exact integration the server runs: same speed, same wall sliding, same
	floor snapping. It owns no Instances, each side moves its own part off `GetPivot`.

	Walls are the map and destructibles only. Arena barriers are left out on purpose: a
	recruit still outside when a fight locks the room walks in through them to hide.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local World = require(Shared.World)
local Types = require(Shared.Types.Recruits)

local WorldFolder = workspace:WaitForChild('World')

--
local RADIUS = 1.25
-- Reaches a little past the step, so it stops just short of a wall instead of inside it.
local SKIN = 0.1
-- How far below its feet it still finds floor: slopes and small ledges, not drops.
local DROP = 4

local function Flat(Vector: Vector3): Vector3
	return Vector3.new(Vector.X, 0, Vector.Z)
end

local function GetWallParams(): RaycastParams
	local Camera = workspace:FindFirstChildOfClass('Camera')
	local Entities = WorldFolder:FindFirstChild('Entities')
	local List = {WorldFolder:FindFirstChild('Map')}

	-- Server keeps destructible colliders under the camera, clients under Entities.
	local ServerDestructibles = Camera and Camera:FindFirstChild('Destructibles')
	local ClientDestructibles = Entities and Entities:FindFirstChild('Destructibles')

	if ServerDestructibles then
		table.insert(List, ServerDestructibles)
	end

	if ClientDestructibles then
		table.insert(List, ClientDestructibles)
	end

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = List

	return Params
end

--[[
	Take the part of `Step` that runs into a wall out, so it slides along it. Zero when the
	slide is blocked as well.
]]
local function Slide(From: Vector3, Step: Vector3, Params: RaycastParams): Vector3
	local Hit = workspace:Spherecast(From, RADIUS, Step + Step.Unit * SKIN, Params)
	if not Hit then
		return Step
	end

	local Normal = Flat(Hit.Normal)
	if Normal.Magnitude <= 1e-3 then
		return Step
	end

	Normal = Normal.Unit

	local Into = Step:Dot(Normal)
	if Into >= 0 then
		return Step
	end

	local Slid = Step - Normal * Into
	if Slid.Magnitude <= 1e-4 or workspace:Spherecast(From, RADIUS, Slid + Slid.Unit * SKIN, Params) then
		return Vector3.zero
	end

	return Slid
end

--
local RecruitMovement = {}
RecruitMovement.__index = RecruitMovement

function RecruitMovement.new(At: CFrame, Speed: number, Height: number?): Types.RecruitMovementClass
	local self = setmetatable({}, RecruitMovement)
	local Look = Flat(At.LookVector)

	self.__Position = At.Position
	self.__Look = if Look.Magnitude > 1e-3 then Look.Unit else Vector3.zAxis
	self.__Direction = Vector3.zero
	self.__Speed = Speed or 0
	self.__Height = Height or 3.15

	return self
end

--- Walk along `Direction` (flattened onto X/Z) at `Speed` studs per second.
function RecruitMovement.Move(self: Types.RecruitMovementClass, Direction: Vector3, Speed: number)
	local Heading = Flat(Direction)
	if Heading.Magnitude <= 1e-3 or Speed <= 0 then
		self:Stop()

		return
	end

	self.__Direction = Heading.Unit
	self.__Speed = Speed
end

function RecruitMovement.Stop(self: Types.RecruitMovementClass)
	self.__Direction = Vector3.zero
end

function RecruitMovement.IsMoving(self: Types.RecruitMovementClass): boolean
	return self.__Direction.Magnitude > 0 and self.__Speed > 0
end

function RecruitMovement.GetDirection(self: Types.RecruitMovementClass): (Vector3, number)
	if not self:IsMoving() then
		return Vector3.zero, 0
	end

	return self.__Direction, self.__Speed
end

function RecruitMovement.GetVelocity(self: Types.RecruitMovementClass): Vector3
	local Direction, Speed = self:GetDirection()

	return Direction * Speed * World:GetSpeed()
end

--- Faces the way it last moved, it does not turn back around when it stops.
function RecruitMovement.GetPivot(self: Types.RecruitMovementClass): CFrame
	return CFrame.lookAlong(self.__Position, self.__Look, Vector3.yAxis)
end

function RecruitMovement.PivotTo(self: Types.RecruitMovementClass, At: CFrame)
	local Look = Flat(At.LookVector)

	self.__Position = At.Position

	if Look.Magnitude > 1e-3 then
		self.__Look = Look.Unit
	end
end

--[[
	Step it along its heading: slides along walls instead of stopping dead on them, follows
	the floor up steps and down slopes, and will not walk off into nothing. A ledge counts as
	a wall, so whoever drives it gets to notice it is stuck.
]]
function RecruitMovement.Update(self: Types.RecruitMovementClass, Delta: number)
	if not self:IsMoving() then
		return
	end

	local Step = self.__Direction * self.__Speed * Delta * World:GetSpeed()
	if Step.Magnitude <= 1e-4 then
		return
	end

	self.__Look = self.__Direction

	Step = Slide(self.__Position, Step, GetWallParams())
	if Step.Magnitude <= 1e-4 then
		return
	end

	local FloorParams = World:GetMapParams(false) :: RaycastParams
	local Floor = workspace:Raycast(self.__Position + Step, Vector3.yAxis * -(self.__Height + DROP), FloorParams)
	if not Floor then
		return
	end

	self.__Position = Floor.Position + Vector3.yAxis * self.__Height
end

--- Drop onto whatever floor is under it, for spawning and teleports.
function RecruitMovement.SnapToGround(self: Types.RecruitMovementClass)
	local FloorParams = World:GetMapParams(false) :: RaycastParams
	local Floor = workspace:Raycast(self.__Position + Vector3.yAxis * 2, Vector3.yAxis * -100, FloorParams)

	if Floor then
		self.__Position = Floor.Position + Vector3.yAxis * self.__Height
	end
end

return RecruitMovement
