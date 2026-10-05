local Default = require(script.Parent)
local Stages = require(script.Parent.Stages)
local Signal = require(script.Parent.Parent.Utility.Signal)

--[[
	One recruit's data: its `Database/Recruits` entry with whatever the mission passed merged
	on top. Every field is documented in `Database/Recruits/Template`.
]]
export type RecruitData = {
	Display_Name: string,
	Model: string,

	Appearance: {
		Height: number,
	},

	Stats: {
		Shield: number,
		Walk_Speed: number,
		Shield_Regen_Rate: number,
		Shield_Regen_Delay: number,
		Hit_Invulnerability: number,
		Flinch_Time: number,
		Aggro_Weight: number,
	},

	Follow: {
		Distance: number,
		Crumb_Spacing: number,
		Leash: number,
		Stuck_Time: number,
	},

	Combat: {
		Corner_Inset: number,
	},

	On_Defeat: {
		Fail_Mission: boolean,
		SetValues: {[string]: any}?,
	},
}

export type RecruitState = "Idle" | "Following" | "Hiding" | "Flinching"

--- Anything a recruit can follow: an agent, or the recruit ahead of it in line.
export type Leader = {
	GetPivot: (self: any) -> (CFrame),
}

--[[
	What RecruitService works out for a recruit every tick, so the class itself never looks
	the world up.
]]
export type RecruitStepContext = {
	--- Who it follows: the owner's active agent, or the recruit ahead of it. Nil holds it in place.
	Leader: Leader?,

	--- The fight its owner is in, nil when there is none.
	Arena: Stages.Arena?,

	--- Height the owner stands at. Floor inside `Arena` is looked for from here.
	Level: number?,

	--- Corners of `Arena` other recruits already hide in, by index. A new pick is added to it.
	ClaimedCorners: {[number]: boolean},
}

export type RecruitMovementClass = {
	__Position: Vector3,
	__Direction: Vector3,
	__Look: Vector3,
	__Speed: number,
	__Height: number,

	Move: (self: RecruitMovementClass, Direction: Vector3, Speed: number) -> (),
	Stop: (self: RecruitMovementClass) -> (),
	IsMoving: (self: RecruitMovementClass) -> (boolean),
	Update: (self: RecruitMovementClass, Delta: number) -> (),
	PivotTo: (self: RecruitMovementClass, At: CFrame) -> (),
	SnapToGround: (self: RecruitMovementClass) -> (),
	GetPivot: (self: RecruitMovementClass) -> (CFrame),
	GetVelocity: (self: RecruitMovementClass) -> (Vector3),

	--- Heading (world X/Z unit vector, zero while stopped) and speed it is moving at.
	GetDirection: (self: RecruitMovementClass) -> (Vector3, number),
}

export type RecruitBrainClass = {
	__Recruit: ServerRecruitClass,
	__Trail: {Vector3},
	__Holding: boolean,
	__Arena: Stages.Arena?,
	__Spot: Vector3?,
	__Corner: number,
	__Stuck_From: Vector3?,
	__Stuck_Time: number,

	Think: (self: RecruitBrainClass, Delta: number, Context: RecruitStepContext) -> (),
	Reset: (self: RecruitBrainClass) -> (),
	ClearTrail: (self: RecruitBrainClass) -> (),

	--- Arena it is hiding in and which corner of it (0 for the centre), nil when not hiding.
	GetHidingSpot: (self: RecruitBrainClass) -> (Stages.Arena?, number),

	__Follow: (self: RecruitBrainClass, Delta: number, Context: RecruitStepContext) -> (),
	__Hide: (self: RecruitBrainClass, Delta: number, Context: RecruitStepContext) -> (),
	__WalkTo: (self: RecruitBrainClass, Goal: Vector3) -> (),
	__IsStuck: (self: RecruitBrainClass, Delta: number) -> (boolean),
	__BehindLeader: (self: RecruitBrainClass, Leader: Leader) -> (Vector3),
	__Teleport: (self: RecruitBrainClass, At: Vector3) -> (),
}

export type ServerRecruitClass = {
	--- Its kind, the `Database/Recruits` module it was built from.
	Name: string,

	Hit: Signal.ScriptSignal<number, any>,
	Defeated: Signal.ScriptSignal<any?>,
	OwnerChanged: Signal.ScriptSignal<Player?>,
	StateChanged: Signal.ScriptSignal<RecruitState>,
	Teleported: Signal.ScriptSignal<CFrame>,

	__Id: number,
	__Data: RecruitData,
	__Owner: Player?,
	__State: RecruitState,
	__Shield: number,
	__Max_Shield: number,
	__Regen_Progress: number,
	__Last_Hit: number,
	__Flinch_Until: number,
	__Defeated: boolean,
	__Active: boolean,
	__Tags: {[string]: thread},
	__Movement: RecruitMovementClass,
	__Brain: RecruitBrainClass,
	__Hitbox: BasePart,
	__Debug_Part: BasePart?,

	-- Enemy-target contract, what ServerEnemy / EntityBehaviorService / Targets call on a target
	GetId: (self: ServerRecruitClass) -> (number),
	GetPivot: (self: ServerRecruitClass) -> (CFrame),
	GetHitbox: (self: ServerRecruitClass) -> (BasePart),
	GetTotalVelocity: (self: ServerRecruitClass) -> (Vector3),
	GetState: (self: ServerRecruitClass) -> (RecruitState),
	IsAlive: (self: ServerRecruitClass) -> (boolean),

	--- Owned, standing and still in the run: what makes it targetable and hittable.
	IsActive: (self: ServerRecruitClass) -> (boolean),
	AddTag: (self: ServerRecruitClass, Tag: string, Time: number?) -> (),
	RemoveTag: (self: ServerRecruitClass, Tag: string) -> (),
	HasTag: (self: ServerRecruitClass, Tag: string) -> (boolean),

	-- Owner
	GetOwner: (self: ServerRecruitClass) -> (Player?),
	SetOwner: (self: ServerRecruitClass, Owner: Player?) -> (),

	-- Shield
	--[[
		Take an enemy hit, worth `Data.Shield_Hits` (1 by default).
		@return The shield it took, 0 when the hit was ignored.
	]]
	TakeHit: (self: ServerRecruitClass, Perpetrator: any, Data: {Shield_Hits: number?}?) -> (number),
	GetShield: (self: ServerRecruitClass) -> (number, number),
	SetShield: (self: ServerRecruitClass, Shield: number) -> (),

	--[[
		Add shield back, fractions carry over between calls.
		@return Whether the whole-number shield changed.
	]]
	RegenShield: (self: ServerRecruitClass, Amount: number) -> (boolean),
	GetTimeSinceHit: (self: ServerRecruitClass) -> (number),
	IsDefeated: (self: ServerRecruitClass) -> (boolean),
	Defeat: (self: ServerRecruitClass, Perpetrator: any?) -> (),

	-- Running
	GetData: (self: ServerRecruitClass) -> (RecruitData),
	GetAggroWeight: (self: ServerRecruitClass) -> (number),
	GetDirection: (self: ServerRecruitClass) -> (Vector3, number),
	GetHidingSpot: (self: ServerRecruitClass) -> (Stages.Arena?, number),
	SetActive: (self: ServerRecruitClass, State: boolean) -> (),
	PivotTo: (self: ServerRecruitClass, At: CFrame) -> (),
	Step: (self: ServerRecruitClass, Delta: number, Context: RecruitStepContext) -> (),
	Destroy: (self: ServerRecruitClass) -> (),

	__SetState: (self: ServerRecruitClass, State: RecruitState) -> (),
	__SyncParts: (self: ServerRecruitClass) -> (),
}

export type ClientRecruitClass = {
	Name: string,

	__Id: number,
	__Owner_Id: number,
	__State: RecruitState,
	__Shield: number,
	__Max_Shield: number,
	__Display_Name: string,
	__Movement: RecruitMovementClass,
	__Correction: Vector3,
	__Anchor: BasePart,
	__Appearance: Default.AppearanceController,
	__Animator: {[string]: any},
	__Indicator: BillboardGui?,
	__Connection: RBXScriptConnection?,

	Init: (self: ClientRecruitClass) -> (),
	Update: (self: ClientRecruitClass, Delta: number) -> (),

	--- Last heading the server sent, integrated locally until the next one.
	Move: (self: ClientRecruitClass, Direction: Vector3, Speed: number) -> (),

	--[[
		Reconcile with the server's position: small errors are smoothed out, large ones and
		teleports snap.
	]]
	Sync: (self: ClientRecruitClass, At: CFrame, Teleport: boolean?) -> (),
	DisplayHit: (self: ClientRecruitClass, Hits: number, Shield: number) -> (),
	SetShield: (self: ClientRecruitClass, Shield: number, Max: number) -> (),
	SetOwner: (self: ClientRecruitClass, OwnerId: number) -> (),
	SetState: (self: ClientRecruitClass, State: RecruitState) -> (),

	IsOwner: (self: ClientRecruitClass, Player: Player) -> (boolean),
	IsMoving: (self: ClientRecruitClass) -> (boolean),
	GetId: (self: ClientRecruitClass) -> (number),
	GetState: (self: ClientRecruitClass) -> (RecruitState),
	GetPivot: (self: ClientRecruitClass) -> (CFrame),
	GetModel: (self: ClientRecruitClass) -> (Model),
	Destroy: (self: ClientRecruitClass, Reason: number?) -> (),
}

return 0
