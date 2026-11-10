--[[
	Decides where a recruit walks, off what RecruitService hands it each tick:

	- Follow: walk the trail its leader leaves (the owner's agent, or the recruit ahead of
	  it in line). It holds still while the leader is close and drops the trail, so a player
	  walking back into it never makes it back away. It only sets off again once the player
	  has passed it and got `Follow.Distance` away on the other side, which keeps it behind.
	- Hide: in a fight (its owner's, or the one it stands in for an ally) run to the nearest
	  free corner of the arena and stay there.
	- Flee: hit while hiding, run to the safest place: whichever of the other corners or the
	  spot behind its protector (owner's agent, or nearest agent) is farthest from enemies.
	  Behind the protector keeps following them, with the protector between it and the enemies.
	- Leash: following, when it is too far behind its leader or stuck, teleport there. Never
	  in a fight: there it always runs, and picks another spot when stuck.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local World = require(Shared.World)
local Types = require(Shared.Types.Recruits)
local RecruitMovement = require(Shared.Classes.Recruit.RecruitMovement)
local StageTypes = require(Shared.Types.Stages)

--
-- A crumb or a hiding spot this close counts as reached.
local REACH = 1.5
-- Once holding still it only sets off again this far past `Follow.Distance`, no start/stop jitter.
local HYSTERESIS = 1
-- Studs it has to cover inside `Stuck_Time` to not count as stuck.
local STUCK_PROGRESS = 0.5
local MAX_TRAIL = 64
-- How far behind its protector it stands when it hides there.
local BEHIND_DISTANCE = 5
-- Each recruit stands this far (min, max) off the spot it picked, so a group sharing a corner
-- spreads around it like people instead of stacking on one point.
local SPREAD = {2, 4.5}

local CORNERS = {
	Vector3.new(1, 0, 1),
	Vector3.new(1, 0, -1),
	Vector3.new(-1, 0, 1),
	Vector3.new(-1, 0, -1),
}

local function Flat(Vector: Vector3): Vector3
	return Vector3.new(Vector.X, 0, Vector.Z)
end

local function FindFloor(At: Vector3, Height: number): Vector3?
	local Cast = workspace:Raycast(At, Vector3.yAxis * -(Height + 20), RecruitMovement.GetWorldParams())
	if not Cast then
		return nil
	end

	return Cast.Position + Vector3.yAxis * Height
end

--[[
	The corners of an arena, inset from its walls, that have floor under them and nothing
	between them and the arena's middle (a generated room is not always a full rectangle).

	@param Level Height to look for floor from, the owner's, who is inside the arena.
	@return Corner index to spot.
]]
local function GetCorners(Arena: StageTypes.Arena, Level: number, Inset: number, Height: number): {[number]: Vector3}
	local MapParams = RecruitMovement.GetWorldParams()
	local Center = Arena.CFrame.Position
	local Middle = Vector3.new(Center.X, Level, Center.Z)
	local HalfX = math.max(Arena.Size.X / 2 - Inset, 0)
	local HalfZ = math.max(Arena.Size.Z / 2 - Inset, 0)
	local Spots = {}

	for Index, Corner in CORNERS do
		local Point = Arena.CFrame:PointToWorldSpace(Vector3.new(Corner.X * HalfX, 0, Corner.Z * HalfZ))
		local Spot = FindFloor(Vector3.new(Point.X, Level + 1, Point.Z), Height)

		if Spot and not workspace:Raycast(Middle, Spot - Middle, MapParams) then
			Spots[Index] = Spot
		end
	end

	return Spots
end

--[[
	Where to hide: the nearest valid corner no other recruit has taken, the nearest valid
	corner when they are all taken, the arena's middle when none is valid.

	@return The spot, and which corner it is (0 for the middle).
]]
local function PickSpot(Arena: StageTypes.Arena, From: Vector3, Level: number, Inset: number, Height: number, Claimed: {[number]: boolean}): (Vector3, number)
	local Spots = GetCorners(Arena, Level, Inset, Height)

	for _, SkipClaimed in {true, false} do
		local Best, BestCorner, BestDistance = nil, 0, math.huge

		for Index, Spot in Spots do
			if SkipClaimed and Claimed[Index] then
				continue
			end

			local Distance = Flat(Spot - From).Magnitude
			if Distance < BestDistance then
				Best, BestCorner, BestDistance = Spot, Index, Distance
			end
		end

		if Best then
			return Best, BestCorner
		end
	end

	local Center = Arena.CFrame.Position

	return FindFloor(Vector3.new(Center.X, Level + 1, Center.Z), Height) or Vector3.new(Center.X, Level, Center.Z), 0
end

--- Distance from `Spot` to the closest enemy, huge when there is none.
local function Safety(Spot: Vector3, Threats: {Vector3}): number
	local Closest = math.huge

	for _, Threat in Threats do
		Closest = math.min(Closest, Flat(Threat - Spot).Magnitude)
	end

	return Closest
end

--[[
	BEHIND_DISTANCE behind `Protector`, on the side away from the enemy closest to them, kept
	inside the arena. Nil when a wall is in the way or there is no floor there.
]]
local function BehindProtector(Protector: Types.Leader, Threats: {Vector3}, Arena: StageTypes.Arena, Inset: number, Height: number): Vector3?
	local Pivot = Protector:GetPivot()
	local Position = Pivot.Position
	local Nearest, NearestDistance = nil, math.huge

	for _, Threat in Threats do
		local Distance = Flat(Threat - Position).Magnitude

		if Distance < NearestDistance then
			Nearest, NearestDistance = Threat, Distance
		end
	end

	local Away = if Nearest then Flat(Position - Nearest) else -Flat(Pivot.LookVector)
	if Away.Magnitude < 1e-3 then
		return nil
	end

	local Local = Arena.CFrame:PointToObjectSpace(Position + Away.Unit * BEHIND_DISTANCE)
	local HalfX = math.max(Arena.Size.X / 2 - Inset, 0)
	local HalfZ = math.max(Arena.Size.Z / 2 - Inset, 0)
	local Point = Arena.CFrame:PointToWorldSpace(Vector3.new(math.clamp(Local.X, -HalfX, HalfX), Local.Y, math.clamp(Local.Z, -HalfZ, HalfZ)))

	if workspace:Raycast(Position, Point - Position, RecruitMovement.GetWorldParams()) then
		return nil
	end

	return FindFloor(Point + Vector3.yAxis, Height)
end

--
local Brain = {}
Brain.__index = Brain

function Brain.new(Recruit: Types.ServerRecruitClass): Types.RecruitBrainClass
	local self = setmetatable({}, Brain)
	self.__Recruit = Recruit
	self.__Trail = {}
	self.__Holding = true
	self.__Arena = nil
	self.__Spot = nil
	self.__Corner = 0
	self.__Stuck_From = nil
	self.__Stuck_Time = 0
	self.__Flee = false
	self.__Behind = false

	local Angle = math.random() * math.pi * 2
	self.__Offset = Vector3.new(math.cos(Angle), 0, math.sin(Angle)) * (SPREAD[1] + math.random() * (SPREAD[2] - SPREAD[1]))

	return self
end

--- Forget everything it was doing, e.g. on a new owner.
function Brain.Reset(self: Types.RecruitBrainClass)
	self:ClearTrail()

	self.__Holding = true
	self.__Arena = nil
	self.__Spot = nil
	self.__Corner = 0
	self.__Flee = false
	self.__Behind = false
end

--- Hurt: next think it runs for the safest place it can find (only matters mid-fight).
function Brain.Flee(self: Types.RecruitBrainClass)
	self.__Flee = true
end

function Brain.ClearTrail(self: Types.RecruitBrainClass)
	table.clear(self.__Trail)

	self.__Stuck_From = nil
	self.__Stuck_Time = 0
end

function Brain.GetHidingSpot(self: Types.RecruitBrainClass): (StageTypes.Arena?, number)
	return self.__Arena, self.__Corner
end

function Brain.Think(self: Types.RecruitBrainClass, Delta: number, Context: Types.RecruitStepContext)
	if Context.Arena then
		self:__Hide(Delta, Context)
	elseif Context.Leader then
		self.__Flee = false
		self:__Follow(Delta, Context)
	else
		self:Reset()
		self.__Recruit.__Movement:Stop()
		self.__Recruit:__SetState('Idle')
	end
end

function Brain.__Follow(self: Types.RecruitBrainClass, Delta: number, Context: Types.RecruitStepContext)
	local Recruit = self.__Recruit
	local Movement = Recruit.__Movement
	local Follow = Recruit.__Data.Follow
	local Leader = Context.Leader :: Types.Leader

	if self.__Arena then
		--- The fight is over, it picks the trail back up from where it hid.
		self.__Arena, self.__Spot, self.__Corner = nil, nil, 0
		self:ClearTrail()
	end

	Recruit:__SetState('Following')

	local LeaderPosition = Leader:GetPivot().Position
	local Position = Movement.__Position
	local Distance = Flat(LeaderPosition - Position).Magnitude

	if Distance > Follow.Leash then
		self:__Teleport(self:__BehindLeader(Leader))

		return
	end

	local Last = self.__Trail[#self.__Trail]
	if Last == nil or Flat(LeaderPosition - Last).Magnitude >= Follow.Crumb_Spacing then
		table.insert(self.__Trail, LeaderPosition)

		if #self.__Trail > MAX_TRAIL then
			table.remove(self.__Trail, 1)
		end
	end

	local Limit = if self.__Holding then Follow.Distance + HYSTERESIS else Follow.Distance
	if Distance <= Limit then
		self.__Holding = true
		self:ClearTrail()
		Movement:Stop()

		return
	end

	self.__Holding = false

	while self.__Trail[1] and Flat(self.__Trail[1] - Position).Magnitude <= REACH do
		table.remove(self.__Trail, 1)
	end

	self:__WalkTo(self.__Trail[1] or LeaderPosition)

	if self:__IsStuck(Delta) then
		self:__Teleport(self:__BehindLeader(Leader))
	end
end

function Brain.__Hide(self: Types.RecruitBrainClass, Delta: number, Context: Types.RecruitStepContext)
	local Recruit = self.__Recruit
	local Movement = Recruit.__Movement
	local Arena = Context.Arena :: StageTypes.Arena
	local Inset = Recruit.__Data.Combat.Corner_Inset

	Recruit:__SetState('Hiding')

	--- A new fight: run for the nearest free corner.
	if self.__Arena ~= Arena or self.__Spot == nil then
		self.__Arena = Arena
		self.__Behind = false
		self.__Flee = false
		self.__Spot, self.__Corner = PickSpot(Arena, Movement.__Position, Context.Level :: number, Inset, Movement.__Height, Context.ClaimedCorners)
		self.__Holding = false
		self:ClearTrail()
	end

	if self.__Flee then
		self.__Flee = false
		self:__PickSafest(Context)
	end

	--- Behind its protector moves with them; when that spot stops working it goes back to a corner.
	if self.__Behind then
		local Behind = Context.Protector and BehindProtector(Context.Protector, Context.Threats, Arena, Inset / 2, Movement.__Height)

		if Behind then
			self.__Spot = Behind
		else
			self.__Behind = false
			self.__Spot, self.__Corner = PickSpot(Arena, Movement.__Position, Context.Level :: number, Inset, Movement.__Height, Context.ClaimedCorners)
		end
	end

	if self.__Corner > 0 then
		Context.ClaimedCorners[self.__Corner] = true
	end

	local Spot = self:__Spread(self.__Spot :: Vector3)
	local Distance = Flat(Spot - Movement.__Position).Magnitude

	if Distance <= (if self.__Behind then REACH + HYSTERESIS else REACH) then
		Movement:Stop()

		self.__Stuck_From = nil
		self.__Stuck_Time = 0

		return
	end

	--- Always runs there, however far: a fight's corners can be farther than the follow leash.
	self:__WalkTo(Spot, Recruit.__Data.Stats.Run_Speed)

	--- Stuck mid-fight: try somewhere else rather than teleport in front of everyone.
	if self:__IsStuck(Delta) then
		self.__Stuck_From = nil
		self.__Stuck_Time = 0
		self:__PickSafest(Context)
	end
end

--[[
	Hurt mid-fight: pick whichever is farthest from every enemy out of the other corners and
	the spot behind its protector. Stays put when nothing qualifies.
]]
function Brain.__PickSafest(self: Types.RecruitBrainClass, Context: Types.RecruitStepContext)
	local Recruit = self.__Recruit
	local Movement = Recruit.__Movement
	local Arena = Context.Arena :: StageTypes.Arena
	local Inset = Recruit.__Data.Combat.Corner_Inset

	local Best, BestCorner, BestBehind, BestSafety = nil, 0, false, -1

	for Index, Spot in GetCorners(Arena, Context.Level :: number, Inset, Movement.__Height) do
		if Index == self.__Corner and not self.__Behind then
			continue
		end

		local Safe = Safety(Spot, Context.Threats)
		if Safe > BestSafety then
			Best, BestCorner, BestBehind, BestSafety = Spot, Index, false, Safe
		end
	end

	if Context.Protector and not self.__Behind then
		local Behind = BehindProtector(Context.Protector, Context.Threats, Arena, Inset / 2, Movement.__Height)

		if Behind and Safety(Behind, Context.Threats) > BestSafety then
			Best, BestCorner, BestBehind = Behind, 0, true
		end
	end

	if Best then
		self.__Spot, self.__Corner, self.__Behind = Best, BestCorner, BestBehind
		self:ClearTrail()
	end
end

--- Its own place around `Spot` (see SPREAD), or `Spot` itself when a wall or a drop is in the way.
function Brain.__Spread(self: Types.RecruitBrainClass, Spot: Vector3): Vector3
	if workspace:Raycast(Spot, self.__Offset, RecruitMovement.GetWorldParams()) then
		return Spot
	end

	return FindFloor(Spot + self.__Offset + Vector3.yAxis, self.__Recruit.__Movement.__Height) or Spot
end

function Brain.__WalkTo(self: Types.RecruitBrainClass, Goal: Vector3, Speed: number?)
	local Recruit = self.__Recruit
	local Movement = Recruit.__Movement

	Movement:Move(Flat(Goal - Movement.__Position), Speed or Recruit.__Data.Stats.Walk_Speed)
end

--[[
	Whether it has been trying to walk for `Stuck_Time` without covering STUCK_PROGRESS studs.
	Time only counts at world speed, so a slowed or stopped world never reads as stuck.
]]
function Brain.__IsStuck(self: Types.RecruitBrainClass, Delta: number): boolean
	local Position = self.__Recruit.__Movement.__Position

	if self.__Stuck_From == nil or Flat(Position - self.__Stuck_From).Magnitude >= STUCK_PROGRESS then
		self.__Stuck_From = Position
		self.__Stuck_Time = 0

		return false
	end

	self.__Stuck_Time += Delta * World:GetSpeed()

	return self.__Stuck_Time >= self.__Recruit.__Data.Follow.Stuck_Time
end

--[[
	Where to put it back when it has to teleport: on the leader's trail `Follow.Distance`
	behind them, or straight behind the leader when the trail is unusable (empty, or broken
	by the leader teleporting away).
]]
function Brain.__BehindLeader(self: Types.RecruitBrainClass, Leader: Types.Leader): Vector3
	local Recruit = self.__Recruit
	local Follow = Recruit.__Data.Follow
	local Height = Recruit.__Movement.__Height
	local Pivot = Leader:GetPivot()
	local LeaderPosition = Pivot.Position

	local Travelled = 0
	local Previous = LeaderPosition

	for Index = #self.__Trail, 1, -1 do
		local Crumb = self.__Trail[Index]

		Travelled += Flat(Previous - Crumb).Magnitude
		Previous = Crumb

		if Travelled < Follow.Distance then
			continue
		end

		if Flat(Crumb - LeaderPosition).Magnitude <= Follow.Distance * 2 then
			return FindFloor(Crumb + Vector3.yAxis, Height) or Crumb
		end

		break
	end

	local Back = Flat(Pivot.LookVector)
	Back = if Back.Magnitude > 1e-3 then Back.Unit else Vector3.zAxis

	local Behind = LeaderPosition - Back * Follow.Distance
	local Blocked = workspace:Raycast(LeaderPosition, Behind - LeaderPosition, RecruitMovement.GetWorldParams())

	if not Blocked then
		local Spot = FindFloor(Behind + Vector3.yAxis, Height)
		if Spot then
			return Spot
		end
	end

	return LeaderPosition
end

--- Teleport to `At`, facing the way it would have walked there.
function Brain.__Teleport(self: Types.RecruitBrainClass, At: Vector3)
	local Recruit = self.__Recruit
	local Movement = Recruit.__Movement
	local Travel = Flat(At - Movement.__Position)
	local Look = if Travel.Magnitude > 1e-3 then Travel.Unit else Movement.__Look

	self.__Holding = true
	Movement:Stop()

	Recruit:PivotTo(CFrame.lookAlong(At, Look))
end

return Brain
