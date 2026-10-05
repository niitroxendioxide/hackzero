--[[
	@class RecruitService

	Owns every recruit on the server: the escort of an Escort mission, or anyone the players
	pick up along the way. Spawns them and keeps each owner's line in order. Every tick it
	works out who each one follows, whether its owner is mid-fight and whether anything is
	after it, then steps them and tells the clients the little they need: a heading when it
	changes, a snap every second, hits and shield.

	Reassigning a recruit is a code call, `SetOwner`. The only time it happens on its own is
	an owner leaving or losing their whole team: their recruits go to the nearest player
	still standing.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Heap = require(Shared.Utility.Heap)
local Signal = require(Shared.Utility.Signal)
local Network = require(Shared.Network)
local Places = require(Shared.Places)
local World = require(Shared.World)
local Debugger = require(Shared.Utility.Debugger)
local Enemies = require(Shared.Libraries.Enemies)
local Types = require(Shared.Types.Recruits)
local StageTypes = require(Shared.Types.Stages)
local AgentTypes = require(Shared.Types.Agents)
local RecruitsDatabase = require(Shared.Database.Recruits)

local ServerRecruit = require(Modules.Classes.Combat.ServerRecruit)
local RecruitList = require(Modules.Libraries.RecruitList)
local EntityReplicator = require(Modules.Libraries.EntityReplicator)
local AgentService = require(Modules.Services.Combat.AgentService)

--
const MAX_RECRUITS = 64
const UPDATE_RATE = 1 / 24
-- A hitch longer than this is stepped as this, so a lag spike can't carry one through a wall.
const MAX_DELTA = 0.2
const SNAP_INTERVAL = 1
const MOVE_INTERVAL = 0.1
-- Heading change past which a new MoveRecruit goes out, as a cosine (8 degrees).
const MOVE_TURN = math.cos(math.rad(8))

--- What was last sent about a recruit, and how long it has been safe for.
type Tracking = {
	Direction: Vector3,
	Speed: number,
	Last_Move: number,
	Last_Snap: number,
	Safe_Since: number?,
}

type Recruit = Types.ServerRecruitClass

local Service = {
	__Ids = nil :: Heap.Heap?,
	__Lines = {} :: {[Player]: {Recruit}},
	__Tracking = {} :: {[Recruit]: Tracking},
	__Mission = nil :: StageTypes.MissionClass?,

	--- (Recruit, ShieldTaken, Perpetrator) on every hit that lands.
	RecruitHit = Signal.new() :: Signal.ScriptSignal<Recruit, number, any>,

	--- (Recruit, Perpetrator) when one goes down, right before it is removed.
	RecruitDefeated = Signal.new() :: Signal.ScriptSignal<Recruit, any>,
}

-- # Privates

--- The player's active agent, when it is standing.
local function GetActiveAgent(Player: Player): AgentTypes.ServerAgentClass?
	local Agent = AgentService:GetCurrentCharacter(Player)
	if Agent and Agent:IsAlive() then
		return Agent
	end

	return nil
end

local function HasStandingAgent(Player: Player): boolean
	for _, Agent in AgentService:GetCharacters(Player) do
		if Agent:IsAlive() then
			return true
		end
	end

	return false
end

--- Nearest player to `Target` with an agent standing, `Excluding` aside.
local function FindNearestOwner(Target: Recruit, Excluding: Player?): Player?
	local Position = Target:GetPivot().Position
	local Nearest, NearestDistance = nil, math.huge

	for _, Player in Players:GetPlayers() do
		if Player == Excluding then
			continue
		end

		local Agent = GetActiveAgent(Player)
		if not Agent then
			continue
		end

		local Distance = (Agent:GetPivot().Position - Position).Magnitude
		if Distance < NearestDistance then
			Nearest, NearestDistance = Player, Distance
		end
	end

	return Nearest
end

--- Everything some living enemy is after right now.
local function GetEnemyTargets(): {[any]: boolean}
	local Targeted = {}

	for _, Enemy in Enemies:GetAll() do
		if not Enemy:IsAlive() then
			continue
		end

		local Target = Enemy:GetTarget()
		if Target ~= nil then
			Targeted[Target] = true
		end
	end

	return Targeted
end

local function IsOwnerTargeted(Owner: Player, Targeted: {[any]: boolean}): boolean
	for _, Agent in AgentService:GetCharacters(Owner) do
		if Targeted[Agent] then
			return true
		end
	end

	return false
end

local function RemoveFromLine(Owner: Player, Target: Recruit)
	local Line = Service.__Lines[Owner]
	if not Line then
		return
	end

	local Index = table.find(Line, Target)
	if Index then
		table.remove(Line, Index)
	end

	if #Line == 0 then
		Service.__Lines[Owner] = nil
	end
end

--- Move it to the end of `Owner`'s line, nothing sent.
local function Assign(Target: Recruit, Owner: Player?)
	local Previous = Target:GetOwner()
	if Previous == Owner then
		return
	end

	if Previous then
		RemoveFromLine(Previous, Target)
	end

	if Owner then
		local Line = Service.__Lines[Owner] or {}
		Service.__Lines[Owner] = Line

		table.insert(Line, Target)
	end

	Target:SetOwner(Owner)
end

-- # Publics

function Service:Init()
	--- Made ahead of the fight check like MatchService's 'Match', so lobby clients still find the remote.
	Network.new(EntityReplicator.CHANNEL, 'Event')

	if not Places:CanFight() then
		return
	end

	Service.__Ids = Heap.new(MAX_RECRUITS)

	local Clock = os.clock()
	RunService.Heartbeat:Connect(function()
		local Delta = os.clock() - Clock
		if Delta < UPDATE_RATE then
			return
		end

		Clock = os.clock()
		Service:__Update(math.min(Delta, MAX_DELTA))
	end)
end

--[[
	Spawn a recruit.

	```lua
	RecruitService:Create('Template', Player, Agent:GetPivot() * CFrame.new(0, 0, 6), {
		Display_Name = 'Rin',
		Stats = { Shield = 8 },
	})
	```

	@param Name      Its kind out of `Database/Recruits`. An unknown kind gets the Template.
	@param Owner     Player it follows. Nil leaves it idle where it stands until `SetOwner`.
	@param At        Where it stands, dropped onto the floor below.
	@param Overrides Merged over its data, see `Database/Recruits/Template` for the fields.

	@return The recruit, nil when this place can't fight or every id is taken.
]]
function Service:Create(Name: string, Owner: Player?, At: CFrame, Overrides: {[string]: any}?): Recruit?
	local Ids = Service.__Ids
	if not Ids then
		Debugger:WarnLine("RecruitService::Create", "Recruits only exist in places that can fight.", 1)

		return nil
	end

	local Id = Ids:extract()
	if not Id then
		Debugger:WarnLine("RecruitService::Create", `No id left for recruit "{Name}", {MAX_RECRUITS} are already standing.`, 1)

		return nil
	end

	if not RecruitsDatabase:Has(Name) then
		Debugger:DebugLine("RecruitService::Create", `No recruit data named "{Name}", using the Template.`, 1)
	end

	local New = ServerRecruit.new(Id, Name, RecruitsDatabase:Resolve(Name, Overrides), At)

	RecruitList:Add(New)
	Service.__Tracking[New] = {
		Direction = Vector3.zero,
		Speed = 0,
		Last_Move = 0,
		Last_Snap = os.clock(),
		Safe_Since = nil,
	}

	--- Signals may run deferred, so anything that can land after a removal checks for it.
	New.Hit:Connect(function(Hits: number, Perpetrator: any)
		EntityReplicator:HitRecruit(New, Hits, Perpetrator)
		Service.RecruitHit:Fire(New, Hits, Perpetrator)
	end)

	New.Defeated:Connect(function(Perpetrator: any)
		Service:__Defeat(New, Perpetrator)
	end)

	New.StateChanged:Connect(function()
		if not RecruitList:Has(New) then
			return
		end

		EntityReplicator:SetRecruitState(New)
		Service:__Snap(New, false)
	end)

	New.Teleported:Connect(function()
		if not RecruitList:Has(New) then
			return
		end

		Service:__Snap(New, true)
	end)

	if Service.__Mission and Service.__Mission:IsFinished() then
		New:SetActive(false)
	end

	Assign(New, Owner)
	EntityReplicator:CreateRecruit(New)

	return New
end

--[[
	Hand a recruit to a player, or to nobody: nil leaves it idle where it stands. It joins the
	end of the new owner's line, behind any recruit they already lead.
]]
function Service:SetOwner(Target: Recruit, Owner: Player?)
	if not RecruitList:Has(Target) or Target:GetOwner() == Owner then
		return
	end

	Assign(Target, Owner)
	EntityReplicator:SetRecruitOwner(Target)
end

--[[
	Take a recruit out of the run.

	@param Reason `GameEnum.EntityRemoveReason`, Removed by default. Defeated plays its death.
]]
function Service:Remove(Target: Recruit, Reason: number?)
	if not RecruitList:Has(Target) then
		return
	end

	local Owner = Target:GetOwner()
	if Owner then
		RemoveFromLine(Owner, Target)
	end

	RecruitList:Remove(Target)
	Service.__Tracking[Target] = nil

	EntityReplicator:RemoveRecruit(Target, Reason or GameEnum.EntityRemoveReason.Removed)

	local Ids = Service.__Ids :: Heap.Heap
	Ids:insert(Target:GetId())

	Target:Destroy()
end

function Service:Get(Id: number): Recruit?
	return RecruitList:Get(Id)
end

--- Recruits `Owner` leads, front of the line first. Every recruit when `Owner` is nil.
function Service:GetRecruits(Owner: Player?): {Recruit}
	if Owner then
		return table.clone(Service.__Lines[Owner] or {})
	end

	local All = {}
	for _, Standing in RecruitList:GetAll() do
		table.insert(All, Standing)
	end

	return All
end

--[[
	The mission fights are read off and defeats report to. MatchService binds it before the
	mission begins, so a Begin hook can already spawn the escort. Once it finishes every
	recruit stands down: still, untargetable, unhittable.
]]
function Service:BindMission(Mission: StageTypes.MissionClass)
	Service.__Mission = Mission

	Mission.Finished:Once(function()
		for _, Standing in RecruitList:GetAll() do
			Standing:SetActive(false)
		end
	end)
end

--- Catch a player who joined late up on every recruit (TeamService:Sync).
function Service:Load(Player: Player)
	for _, Standing in RecruitList:GetAll() do
		EntityReplicator:CreateRecruit(Standing, Player)
		EntityReplicator:SetRecruitState(Standing, Player)

		local _, Speed = Standing:GetDirection()
		if Speed > 0 then
			EntityReplicator:MoveRecruit(Standing, Player)
		end
	end
end

--[[
	Give away everything `Player` leads, each recruit to the nearest player still standing,
	or to nobody when there is none. TeamService calls it when a player leaves.
]]
function Service:ReleasePlayer(Player: Player)
	local Line = Service.__Lines[Player]
	if not Line then
		return
	end

	for _, Led in table.clone(Line) do
		Service:SetOwner(Led, FindNearestOwner(Led, Player))
	end
end

-- # Running

function Service:__Update(Delta: number)
	local Mission = Service.__Mission
	local Targeted = GetEnemyTargets()

	--- A line whose owner left, or lost every agent while someone else still stands, changes hands.
	for Owner, Line in table.clone(Service.__Lines) do
		local Left = Owner.Parent == nil
		local Wiped = not Left and Line[1] ~= nil and not HasStandingAgent(Owner) and FindNearestOwner(Line[1], Owner) ~= nil

		if Left or Wiped then
			Service:ReleasePlayer(Owner)
		end
	end

	--- Corners already taken, so recruits sharing an arena spread out.
	local Claimed = {} :: {[StageTypes.Arena]: {[number]: boolean}}
	for _, Standing in RecruitList:GetAll() do
		local Arena, Corner = Standing:GetHidingSpot()

		if Arena and Corner > 0 then
			Claimed[Arena] = Claimed[Arena] or {}
			Claimed[Arena][Corner] = true
		end
	end

	for Owner, Line in table.clone(Service.__Lines) do
		local Agent = GetActiveAgent(Owner)
		local AgentPosition = if Agent then Agent:GetPivot().Position else nil
		local Arena = if Mission and AgentPosition then Mission:GetCombatAreaAt(AgentPosition) else nil
		local OwnerTargeted = IsOwnerTargeted(Owner, Targeted)

		if Arena and not Claimed[Arena] then
			Claimed[Arena] = {}
		end

		--- Single file: the first one follows the owner's agent, everyone else the one ahead.
		local Leader: Types.Leader? = Agent
		for _, Led in table.clone(Line) do
			Led:Step(Delta, {
				Leader = Leader,
				Arena = Arena,
				Level = if AgentPosition then AgentPosition.Y else nil,
				ClaimedCorners = if Arena then Claimed[Arena] else {},
			})

			Service:__Regen(Led, Delta, Arena == nil and not OwnerTargeted and not Targeted[Led])
			Service:__Replicate(Led)

			Leader = Led
		end
	end

	for _, Standing in RecruitList:GetAll() do
		if Standing:GetOwner() ~= nil then
			continue
		end

		Standing:Step(Delta, {
			Leader = nil,
			Arena = nil,
			Level = nil,
			ClaimedCorners = {},
		})

		Service:__Regen(Standing, Delta, not Targeted[Standing])
		Service:__Replicate(Standing)
	end
end

--[[
	Shield comes back once it has been out of combat, and unhit, for `Shield_Regen_Delay`.
	Out of combat means its owner is not inside a running fight's arena and no enemy is after
	the recruit or any of its owner's agents.
]]
function Service:__Regen(Target: Recruit, Delta: number, Safe: boolean)
	local Track = Service.__Tracking[Target]
	if not Track then
		return
	end

	if not Safe then
		Track.Safe_Since = nil

		return
	end

	local Now = os.clock()
	Track.Safe_Since = Track.Safe_Since or Now

	local Stats = Target:GetData().Stats
	if Now - (Track.Safe_Since :: number) < Stats.Shield_Regen_Delay or Target:GetTimeSinceHit() < Stats.Shield_Regen_Delay then
		return
	end

	if Target:RegenShield(Stats.Shield_Regen_Rate * Delta * World:GetSpeed()) then
		EntityReplicator:SetRecruitShield(Target)
	end
end

--[[
	Send what the clients need to keep predicting it: a heading on start/stop and when it
	turns past MOVE_TURN, a snap every SNAP_INTERVAL while it walks and one when it stops.
]]
function Service:__Replicate(Target: Recruit)
	local Track = Service.__Tracking[Target]
	if not Track then
		return
	end

	local Now = os.clock()
	local Direction, Speed = Target:GetDirection()
	local Moving = Speed > 0

	if Moving ~= (Track.Speed > 0) then
		Track.Direction, Track.Speed, Track.Last_Move = Direction, Speed, Now
		EntityReplicator:MoveRecruit(Target)

		--- Stopping lands it exactly where the server has it.
		if not Moving then
			Service:__Snap(Target, false)
		end

		return
	end

	if not Moving then
		return
	end

	local Turned = Direction:Dot(Track.Direction) < MOVE_TURN
	local Changed = math.abs(Speed - Track.Speed) > 0.5

	if (Turned or Changed) and Now - Track.Last_Move >= MOVE_INTERVAL then
		Track.Direction, Track.Speed, Track.Last_Move = Direction, Speed, Now
		EntityReplicator:MoveRecruit(Target)
	end

	if Now - Track.Last_Snap >= SNAP_INTERVAL then
		Service:__Snap(Target, false)
	end
end

function Service:__Snap(Target: Recruit, Teleport: boolean)
	local Track = Service.__Tracking[Target]
	if Track then
		Track.Last_Snap = os.clock()
	end

	EntityReplicator:SnapRecruit(Target, Teleport)
end

--[[
	What a defeat means for the run comes off its `On_Defeat`: SetValues go to the mission
	(watchers decide what follows), and `Fail_Mission` ends the run as a loss.
]]
function Service:__Defeat(Target: Recruit, Perpetrator: any)
	if not RecruitList:Has(Target) then
		return
	end

	local OnDefeat = Target:GetData().On_Defeat or {}
	local Mission = Service.__Mission

	Service.RecruitDefeated:Fire(Target, Perpetrator)
	Service:Remove(Target, GameEnum.EntityRemoveReason.Defeated)

	if not Mission or Mission:IsFinished() then
		return
	end

	if typeof(OnDefeat.SetValues) == 'table' then
		Mission:ApplySetValues(OnDefeat.SetValues)
	end

	if OnDefeat.Fail_Mission == true and not Mission:IsFinished() then
		Mission:Finish(false)
	end
end

return Service
