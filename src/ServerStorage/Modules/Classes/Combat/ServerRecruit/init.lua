--[[
	@class ServerRecruit

	Someone the players escort: follows one player around, hides in a corner while that
	player is in a fight, and soaks enemy hits on a shield counted in hits rather than damage.

	It never looks the world up on its own. RecruitService works out who it follows, whether
	a fight is on and whether anything is after it, and hands that over through `Step`, so
	this stays free of service requires. Brain.lua decides the walking.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local settings = require(ServerStorage.Modules[".testenv"].settings)
local Signal = require(Shared.Utility.Signal)
local Types = require(Shared.Types.Recruits)
local StageTypes = require(Shared.Types.Stages)
local MovementClass = require(Shared.Classes.Recruit.RecruitMovement)
local Brain = require(script.Brain)

-- DEBUG
local SHOW_LOCATION = RunService:IsStudio() and settings.REPLICATE_CONSTANTS.RECRUIT_LOCATIONS == true

--
local function GetHitboxFolder(): Folder
	local Camera = workspace:FindFirstChildOfClass('Camera') :: Camera
	local Folder = Camera:FindFirstChild('Recruits')

	if not Folder then
		Folder = Instance.new('Folder')
		Folder.Name = 'Recruits'
		Folder.Parent = Camera
	end

	return Folder :: Folder
end

local function CreateHitbox(Name: string, Height: number): BasePart
	local Hitbox = Instance.new('Part')
	Hitbox.Name = Name .. 'RecruitHitbox'
	Hitbox.Size = Vector3.new(4, Height * 1.5873015873, 3)
	Hitbox.Anchored = true
	Hitbox.CanCollide = false
	Hitbox.CanTouch = false
	Hitbox.CastShadow = false
	Hitbox.Transparency = 0.85
	Hitbox.Color = Color3.new(1, 0.6, 0)
	Hitbox.Parent = GetHitboxFolder()

	return Hitbox
end

--- A visible copy of the hitbox, for watching the server's recruit before there is a client one.
local function CreateDebugPart(Hitbox: BasePart): BasePart
	local Part = Hitbox:Clone()
	Part.Name = Hitbox.Name .. 'Debug'
	Part.CanQuery = false
	Part.Transparency = 0.5
	Part.Parent = workspace

	return Part
end

--
local ServerRecruit = {}
ServerRecruit.__index = ServerRecruit
ServerRecruit.__tostring = function()
	return 'RecruitClass'
end

--[[
	@param Id   Its id in RecruitService, the one the clients know it by.
	@param Name Its kind, the `Database/Recruits` module `Data` was resolved from.
	@param Data Its own copy of its data, overrides already merged in.
	@param At   Where it stands, dropped onto the floor below.
]]
function ServerRecruit.new(Id: number, Name: string, Data: Types.RecruitData, At: CFrame): Types.ServerRecruitClass
	local self = setmetatable({}, ServerRecruit)
	self.Name = Name

	self.Hit = Signal.new()
	self.Defeated = Signal.new()
	self.OwnerChanged = Signal.new()
	self.StateChanged = Signal.new()
	self.Teleported = Signal.new()

	-- Privates
	self.__Id = Id
	self.__Data = Data
	self.__Owner = nil
	self.__State = 'Idle'
	self.__Shield = Data.Stats.Shield
	self.__Max_Shield = Data.Stats.Shield
	self.__Regen_Progress = 0
	self.__Last_Hit = -math.huge
	self.__Flinch_Until = 0
	self.__Defeated = false
	self.__Active = true
	self.__Tags = {}
	self.__Movement = MovementClass.new(At, Data.Stats.Walk_Speed, Data.Appearance.Height)
	self.__Brain = Brain.new(self)
	self.__Hitbox = CreateHitbox(Name, Data.Appearance.Height)
	self.__Debug_Part = if SHOW_LOCATION then CreateDebugPart(self.__Hitbox) else nil

	self.__Movement:SnapToGround()
	self:__SyncParts()

	return self
end

-- # Target contract, what enemies call on whatever they are after

function ServerRecruit.GetId(self: Types.ServerRecruitClass): number
	return self.__Id
end

function ServerRecruit.GetPivot(self: Types.ServerRecruitClass): CFrame
	return self.__Movement:GetPivot()
end

function ServerRecruit.GetHitbox(self: Types.ServerRecruitClass): BasePart
	return self.__Hitbox
end

function ServerRecruit.GetTotalVelocity(self: Types.ServerRecruitClass): Vector3
	return self.__Movement:GetVelocity()
end

function ServerRecruit.GetState(self: Types.ServerRecruitClass): Types.RecruitState
	return self.__State
end

function ServerRecruit.IsAlive(self: Types.ServerRecruitClass): boolean
	return not self.__Defeated
end

function ServerRecruit.IsActive(self: Types.ServerRecruitClass): boolean
	return self.__Active and not self.__Defeated and self.__Owner ~= nil
end

function ServerRecruit.AddTag(self: Types.ServerRecruitClass, Tag: string, Time: number?)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = task.delay(Time or 5e12, function()
		self.__Tags[Tag] = nil
	end)
end

function ServerRecruit.RemoveTag(self: Types.ServerRecruitClass, Tag: string)
	if self.__Tags[Tag] then
		task.cancel(self.__Tags[Tag])
	end

	self.__Tags[Tag] = nil
end

function ServerRecruit.HasTag(self: Types.ServerRecruitClass, Tag: string): boolean
	return self.__Tags[Tag] ~= nil
end

-- # Owner

function ServerRecruit.GetOwner(self: Types.ServerRecruitClass): Player?
	return self.__Owner
end

--[[
	Hand it to another player, nil leaves it idle where it stands. RecruitService keeps the
	lines and the clients in step, so go through `RecruitService:SetOwner` instead.
]]
function ServerRecruit.SetOwner(self: Types.ServerRecruitClass, Owner: Player?)
	if self.__Owner == Owner then
		return
	end

	self.__Owner = Owner
	self.__Brain:Reset()

	self.OwnerChanged:Fire(Owner)
end

-- # Shield

--[[
	Take an enemy hit. The shield counts hits, not damage: this takes `Shield_Hits` off it
	(1 unless the attack is flagged heavier), then it shrugs off anything else for
	`Hit_Invulnerability` seconds so a multi-hit attack only lands once.

	@return The shield it took, 0 when the hit was ignored.
]]
function ServerRecruit.TakeHit(self: Types.ServerRecruitClass, Perpetrator: any, Data: {Shield_Hits: number?}?): number
	if not self:IsActive() or self:HasTag('Invulnerability') then
		return 0
	end

	local Hits = math.max(math.floor((Data and Data.Shield_Hits) or 1), 0)
	if Hits <= 0 then
		return 0
	end

	local Stats = self.__Data.Stats

	self.__Shield = math.max(self.__Shield - Hits, 0)
	self.__Last_Hit = os.clock()
	self.__Regen_Progress = 0
	self.__Flinch_Until = os.clock() + Stats.Flinch_Time

	self:AddTag('Invulnerability', Stats.Hit_Invulnerability)
	self.Hit:Fire(Hits, Perpetrator)

	if self.__Shield <= 0 then
		self:Defeat(Perpetrator)
	end

	return Hits
end

function ServerRecruit.GetShield(self: Types.ServerRecruitClass): (number, number)
	return self.__Shield, self.__Max_Shield
end

function ServerRecruit.SetShield(self: Types.ServerRecruitClass, Shield: number)
	self.__Shield = math.clamp(math.floor(Shield), 0, self.__Max_Shield)
	self.__Regen_Progress = 0
end

--[[
	Add shield back. Fractions carry over between calls, the shield itself only ever moves in
	whole hits.

	@return Whether the shield changed.
]]
function ServerRecruit.RegenShield(self: Types.ServerRecruitClass, Amount: number): boolean
	if self.__Defeated or self.__Shield >= self.__Max_Shield then
		self.__Regen_Progress = 0

		return false
	end

	self.__Regen_Progress += Amount
	if self.__Regen_Progress < 1 then
		return false
	end

	local Whole = math.floor(self.__Regen_Progress)
	self.__Regen_Progress -= Whole
	self.__Shield = math.min(self.__Shield + Whole, self.__Max_Shield)

	return true
end

function ServerRecruit.GetTimeSinceHit(self: Types.ServerRecruitClass): number
	return os.clock() - self.__Last_Hit
end

function ServerRecruit.IsDefeated(self: Types.ServerRecruitClass): boolean
	return self.__Defeated
end

--- Down for good. What that means for the mission is RecruitService's call, off `Defeated`.
function ServerRecruit.Defeat(self: Types.ServerRecruitClass, Perpetrator: any?)
	if self.__Defeated then
		return
	end

	self.__Defeated = true
	self.__Shield = 0
	self.__Movement:Stop()

	self.Defeated:Fire(Perpetrator)
end

-- # Running

function ServerRecruit.GetData(self: Types.ServerRecruitClass): Types.RecruitData
	return self.__Data
end

--- Enemies picking a target see it this many times farther away than it is.
function ServerRecruit.GetAggroWeight(self: Types.ServerRecruitClass): number
	return self.__Data.Stats.Aggro_Weight or 1
end

function ServerRecruit.GetDirection(self: Types.ServerRecruitClass): (Vector3, number)
	return self.__Movement:GetDirection()
end

function ServerRecruit.GetHidingSpot(self: Types.ServerRecruitClass): (StageTypes.Arena?, number)
	return self.__Brain:GetHidingSpot()
end

--- Off stops it thinking: it stands still and can be neither targeted nor hit, e.g. once the mission is over.
function ServerRecruit.SetActive(self: Types.ServerRecruitClass, State: boolean)
	self.__Active = State
end

function ServerRecruit.PivotTo(self: Types.ServerRecruitClass, At: CFrame)
	self.__Movement:PivotTo(At)
	self.__Brain:ClearTrail()
	self:__SyncParts()

	self.Teleported:Fire(self:GetPivot())
end

function ServerRecruit.Step(self: Types.ServerRecruitClass, Delta: number, Context: Types.RecruitStepContext)
	if self.__Defeated then
		return
	end

	if not self.__Active then
		self.__Movement:Stop()
		self:__SetState('Idle')
	elseif os.clock() < self.__Flinch_Until then
		self.__Movement:Stop()
		self:__SetState('Flinching')
	else
		self.__Brain:Think(Delta, Context)
	end

	self.__Movement:Update(Delta)
	self:__SyncParts()
end

function ServerRecruit.Destroy(self: Types.ServerRecruitClass)
	for _, Thread in self.__Tags do
		task.cancel(Thread)
	end

	table.clear(self.__Tags)

	for _, Event in {self.Hit, self.Defeated, self.OwnerChanged, self.StateChanged, self.Teleported} do
		Event:DisconnectAll()
	end

	self.__Hitbox:Destroy()

	if self.__Debug_Part then
		self.__Debug_Part:Destroy()
	end
end

function ServerRecruit.__SetState(self: Types.ServerRecruitClass, State: Types.RecruitState)
	if self.__State == State then
		return
	end

	self.__State = State
	self.StateChanged:Fire(State)
end

function ServerRecruit.__SyncParts(self: Types.ServerRecruitClass)
	local Pivot = self.__Movement:GetPivot()

	self.__Hitbox.CFrame = Pivot

	if self.__Debug_Part then
		self.__Debug_Part.CFrame = Pivot
	end
end

return ServerRecruit
