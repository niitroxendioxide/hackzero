--
local Common = require(script.Parent.Common)
local StatusTypes = require(script.Parent.Status)
local MovementTypes = require(script.Parent.Movement)

type Artifact = Common.Artifact
type Drive = Common.Drive
type Stat = Common.Stat
type State = Common.State
type AnimatorController = Common.AnimatorController
type CharacterClass = Common.CharacterClass
type StateEffect = Common.StateEffect
type Element = Common.Element
type AgentMovesetAbility = Common.AgentMovesetAbility
type Rig = Common.Rig
type Signal<T...> = Common.Signal<T...>
type Enemy = Common.Enemy
type ClientEnemy = Common.ClientEnemy

type AgentStatusClass = StatusTypes.AgentStatusClass
type EffectParameters = StatusTypes.EffectParameters
type EffectObject = StatusTypes.EffectObject

type ServerCharacterClass = MovementTypes.ServerCharacterClass

--[[ Artifact / gear hook processing ]]
export type ProcessEventData = {
	Agent: ServerAgentClass,
	Target: Enemy?,
	Critical: boolean?,
	Element: Element?,
	SkillId: number?,
	Total_Damage: number?,
	Burst: boolean?,
	SkillUniqueToken: any,
	Multipliers: {
		Damage: number,
		Daze: number,
		Affliction: number,
		Stun: number,
		Affliction_Buildup: number,
	}
}

export type HitProcessState = "Before" | "After"
export type AgentArtifactClass = {
	Name: string,
	Level: number,

	-- #Privates
	__Cache: {},
	__Events: {},

	--
	Extend: (self: AgentArtifactClass, Level: number) -> AgentArtifactClass,

	-- Not implemented on the current ArtifactClass (src/ServerStorage/.../Items/Artifact.lua) - declared for a planned feature.
	GetPieceCount: (self: AgentArtifactClass) -> (number),

	OnEffectProcess: (self: AgentArtifactClass, Event: (Data: ProcessEventData, PieceCount: number) -> ()) -> (),
	OnHitProcess: (self: AgentArtifactClass, State: HitProcessState, Event: (Data: ProcessEventData, PieceCount: number) -> (number, number)) -> (),
	OnEvent: (self: AgentArtifactClass, State: string, Event: (Data: {} & ProcessEventData, PieceCount: number) -> ()) -> (),
	GetEventFor: (self: AgentArtifactClass, EventName: string) -> ((Data: ProcessEventData) -> () | (Effect: Element, Data: ProcessEventData) -> ())?,
}
export type DriveObject = {}

type SkillLevels = {
	Basic_Attack: number,
	Ultimate: number,
	Special: number,
}

export type AssistStruct = {
	TargetId: number,
	Accepted: Signal<nil>,
	Time: number,
}

export type AgentClass = {
	Name: string,
	PlayerId: number,

	__Level: number,
	__User: number,
	__Skill_Thread: thread?,
	__Player_Assigned: Player,
	__Items: AgentItemsClass,
	__Gear: ClientGearManager,
	__Locked: boolean,
	__Skill_Levels: SkillLevels,
	__Limit_Area: BasePart?,
	__Listener_Count: number,
	__Server_Action_Buffer: {number},
	__current_walking_object: any?,
	__Current_Collision_Priority: number?,
	-- Tag name -> the thread that will auto-expire it. See AddTag/RemoveTag/HasTag.
	__Tags: {[string]: thread?},

	GetId: (self: AgentClass) -> (number),
	SetLimitArea: (self: AgentClass, Part: BasePart) -> (),
	GetLimitArea: (self: AgentClass) -> (BasePart),
	IsLocalPlayerOwner: (self: AgentClass) -> (boolean),

	Init: (self: AgentClass) -> (),
	Move: (self: AgentClass) -> (),
	Stop: (self: AgentClass) -> (),
	Update: (self: AgentClass, Delta: number) -> (),
	Look: (self: AgentClass, Direction: Vector3, Instant: boolean?, Bypass: boolean?) -> (),
	GetHitbox: (self: AgentClass) -> (BasePart),

	CanSwitch: (self: AgentClass) -> (boolean),
	--[[
		@param Server If true and a server-replicated position has been recorded, returns that instead of the local pivot.
	]]
	GetPivot: (self: AgentClass, Server: boolean?) -> CFrame,
	GetModel: (self: AgentClass) -> Rig,
	PivotTo: (self: AgentClass) -> CFrame,
	IsMoving: (self: AgentClass) -> boolean,
	IsAlive: (self: AgentClass) -> boolean,
	IsActive: (self: AgentClass) -> boolean,
	IsAirborne: (self: AgentClass) -> boolean,
	Land: (self: AgentClass) -> (),

	GetUltBar: (self: AgentClass) -> (number),
	BlockRotation: (self: AgentClass, Time: number) -> (),
	SetPhysicsEnabled: (self: AgentClass, State: boolean) -> (),
	SetColliderGroupEnabled: (self: AgentClass, Group: {}, State: boolean) -> (),

	LookAtTarget: (self: AgentClass, Target: ClientEnemy) -> (),
	GetAppearance: (self: AgentClass) -> (Common.AnimatorController),
	SetEnemyCollisionState: (self: AgentClass, State: boolean, Priority: number?) -> (),

	--[[
		Wait for a replication server action, to occur
		@param Type The enum value of GameEnum.Replication to wait for.
	]]
	AwaitServerTriggeredAction: (self: AgentClass, Type: number) -> (),
	MarkServerAction: (self: AgentClass, Type: number) -> (),

	--[[
		Walk forward for the specified time
		@param Time the time to walk for
	]]
	Walk: (self: AgentClass, Time: number, Power: number?, Linear: boolean?) -> (),
	--[[
		Walk backwards for the specified time
		@param Time the time to walk backwards for
		@param Power the walk-speed multiplier
		@param Linear whether to decelerate after time or not
	]]
	WalkBack: (self: AgentClass, Time: number, Power: number?) -> (),
	ApplyImpulse: (self: AgentClass, Impulse: Vector3) -> (),

	SetKey: (self: AgentClass, Key: string, State: boolean) -> (),
	GetKey: (self: AgentClass, Key: string) -> boolean,

	GetRotation: (self: AgentClass) -> (Vector3),
	GetCurrentSkill: (self: AgentClass) -> string?,
	GetHealth: (self: AgentClass) -> (number, number),
	GetStat: (self: AgentClass, Stat: Stat) -> number,
	GetState: (self: AgentClass) -> State,
	GetEnergy: (self: AgentClass) -> (number),
	GetSkillLevel: (self: AgentClass, Name: AgentMovesetAbility) -> (),

	--[[
		Sets the current active skill, not recommended to change, used internally.
		@param Time if not specified, infinite.
	]]
	SetCurrentSkill: (self: AgentClass, Skill: string, Time: number?) -> (string),

	GiveEnergy: (self: AgentClass, Amount: number) -> (),
	SetVisible: (self: AgentClass, State: boolean?) -> (),
	SetEnergy: (self: AgentClass, Energy: number) -> (),

	--[[
		(Re)builds the agent's level and status block from the character database. Called by the constructor;
		calling it again fully replaces __Status, it does not just adjust the level number.
	]]
	SetLevel: (self: AgentClass, Amount: number) -> (),
	--[[
		Sets the maximum health, optionally filling current health up to the new max.
	]]
	SetMaxHealth: (self: AgentClass, Amount: number, Fill: boolean?) -> (),
	SetHealth: (self: AgentClass, Amount: number) -> (),
	--[[
		Marks the agent's status as dead and briefly locks state-switching (CanSwitch) to let death handling run.
	]]
	Kill: (self: AgentClass) -> (),
	Revive: (self: AgentClass) -> (),
	IsDead: (self: AgentClass) -> (boolean),

	CreateMeter: (self: AgentClass, Name: string, Data: {Max: number?, EmptySpeed: number?, FillSpeed: number?, Id: number}) -> (),
	UpdateMeter: (self: AgentClass, Meter: string, Amount: number) -> (),
	SetMeter: (self: AgentClass, Meter: string, Amount: number) -> (),
	GetAllMeters: (self: AgentClass) -> ({StatusTypes.AgentMeter}),
	SetMeterUpdateType: (self: AgentClass, Meter: string, Type: number, State: boolean, Handler: (() -> ())?) -> (),
	GetMeter: (self: AgentClass, Name: string) -> (number, number),
	SetUltBar: (self: AgentClass, Amount: number) -> (),

	--[[
		Overwrites the character controller's raw velocity fields directly, used to sync client physics
		state (LinearMovement, SurfaceVelocity, MovementVelocity, LastMovementVelocity) from replication.
	]]
	SyncVelocities: (self: AgentClass, LinearMovement: Vector3?, SurfaceVelocity: Vector3?, MovementVelocity: Vector3?, LastMovementVelocity: Vector3?) -> (),

	AddEffect: (self: AgentClass, Effect: EffectParameters) -> StateEffect,
	AddTrackToState: (self: AgentClass, State: string, Track: AnimationTrack, DisableTime: number) -> (),
	GetEffect: (self: AgentClass, Name: string) -> StateEffect,
	RemoveEffect: (self: AgentClass, Id: number) -> (),

	--[[
		Increase the amount of effects/charges an effect has
		@param Tag The tag to look the effect by
		@param Amount The amount to increase by
		@param RestartThread Whether to restart the timer or not, for timed effects.
	]]
	ChangeEffect: (self: ServerAgentClass, Tag: string, Amount: number?, RestartThread: boolean?) -> (EffectObject),

	---
	GetAnimator: (self: AgentClass) -> AnimatorController,

	--[[
		Not to be confused with ApplyImpulse. This method applies an impulse that keeps aiming forward the rest of the velocity, so if you change your direction, you'll still move with the force given

		@param Power the strength of the initial force applied
		@param FadeOutTime the time it will take for the velocity to reach zero (and be deleted afterwards)
	]]
	ImpulseForward: (self: AgentClass, Power: number, FadeOutTime: number) -> (),

	--[[
		Change the state of the agent to the specified one, this limits/allows specific methods
		@param State The state to switch to, i. e. "Attacking", "Idle", "Stun";
		@param Time The time to remain in that state
	]]
	SwitchState: (self: AgentClass, State: State, Time: number, Unaffected: boolean?) -> (),

	TakeDamage: (self: AgentClass, Amount: number) -> (),
	Heal: (self: AgentClass, Amount: number) -> (),

	AddTag: (self: AgentClass, Tag: string, Time: number) -> (),
	HasTag: (self: AgentClass, Tag: string) -> (boolean),
	RemoveTag: (self: AgentClass, Tag: string) -> (),

	__Character: CharacterClass,
	__Status: AgentStatusClass
}

export type ServerAgentClass = {
	Name: string,

	__Level: number,
	__User: number,
	__Ascension: number,
	-- Never assigned in the current implementation (the Heartbeat block that would set it is commented out) - kept optional.
	__Main_Thread: thread?,
	__Player_Assigned: Player,
	__Status: AgentStatusClass,
	__Items: AgentItemsClass,
	__Skill_Levels: SkillLevels,
	__Last_Skill_Cast: number,
	__Last_Hit_Time: number,
	__Last_Hit_Caster: number,
	__Current_Target: {Data: AssistStruct, Thread: thread}?,
	__Gear: ServerGearManager,
	__Limit_Area: BasePart?,
	__current_walking_object: any?,
	__Meter_updates: {},
	__Current_Collision_Priority: number?,
	-- Tag name -> the thread that will auto-expire it. See AddTag/RemoveTag/HasTag.
	__Tags: {[string]: thread?},
	-- Lazily created on first Update; throttles UpdateCurrentEnergy replication to ~2.5/s.
	__Replication_Clock: number?,

	__Active: boolean,
	__Character: ServerCharacterClass,

	SetLimitArea: (self: AgentClass, Part: BasePart) -> (),
	GetLimitArea: (self: AgentClass) -> (BasePart),
	GetId: (self: ServerAgentClass) -> (number),
	GetAscension: (self: ServerAgentClass) -> (number),
	Init: (self: ServerAgentClass) -> (),
	Stop: (self: ServerAgentClass) -> (),
	Move: (self: ServerAgentClass) -> (),
	Rotate: (self: ServerAgentClass, Angle: Vector3) -> (),
	--[[ Alias for Rotate, kept for parity with the client AgentClass's Look. ]]
	Look: (self: ServerAgentClass, Direction: Vector3) -> (),

	IsActive: (self: ServerAgentClass) -> (boolean),
	SetActive: (self: ServerAgentClass, State: boolean) -> (),
	IsMoving: (self: ServerAgentClass) -> (boolean),
	IsBeingAttacked: (self: ServerAgentClass) -> (boolean),
	Hit: (self: ServerAgentClass, Caster: Enemy, Time: number) -> (),
	GetMarkedTarget: (self: ServerAgentClass) -> (AssistStruct?),

	SetEnemyCollisionState: (self: ServerAgentClass, State: boolean, Priority: number?) -> (),
	SetColliderGroupEnabled: (self: ServerAgentClass, Group: {}, State: boolean) -> (),
	GetTotalVelocity: (self: ServerAgentClass) -> (Vector3),
	OnMeterUpdated: (self: ServerAgentClass, Meter: string, fn: (Id: number, Value: number, Percent: number) -> ()) -> (),
	UpdateMeter: (self: ServerAgentClass, Name: string, Amount: number) -> (),
	CreateMeter: (self: ServerAgentClass, Name: string, Data: {Max: number?, EmptySpeed: number?, FillSpeed: number?, Id: number}) -> (),
	GetMeter: (self: ServerAgentClass, Name: string) -> (number, number),
	GetAllMeters: (self: ServerAgentClass) -> ({Id: number?, [string]: any}),

	GetCurrentSkill: (self: ServerAgentClass) -> (string?),

	--[[
		Not recommended to change, it's used internally to set the skill.
		@param Time if not given, infinite
	]]
	SetCurrentSkill: (self: ServerAgentClass, Skill: string, Time: number?) -> (),

	--[[
		Set to nil for no target
		@param TargetId Number id for enemy
		@param Time how long prompt lasts
	]]
	MarkTarget: (self: ServerAgentClass, TargetId: number?, Time: number?) -> (AssistStruct),

	--[[
		Not to be confused with ApplyImpulse. This method applies an impulse that keeps aiming forward the rest of the velocity, so if you change your direction, you'll still move with the force given

		@param Power the strength of the initial force applied
		@param FadeOutTime the time it will take for the velocity to reach zero (and be deleted afterwards)
	]]
	ImpulseForward: (self: ServerAgentClass, Power: number, FadeOutTime: number) -> (),
	ApplyImpulse: (self: ServerAgentClass, Velocity: Vector3) -> (),
	SetKey: (self: ServerAgentClass, Key: string, Value: any) -> (),
	GetKey: (self: ServerAgentClass, Velocity: Vector3) -> (),

	--[[
		Walk forward for the specified time
		@param Time the time to walk for
		@param Power the power modifier for the speed
		@param Linear whether the movement should decelerate or not
	]]
	Walk: (self: ServerAgentClass, Time: number, Power: number?, Linear: boolean) -> (),

	--[[
		Walk backwards for the specified time
		@param Time the time to walk backwards for
	]]
	WalkBack: (self: ServerAgentClass, Time: number, Power: number?) -> (),

	--[[
		@param Meter The name of the meter to set the update type state to
		@param Type The type of meter update to toggle (GameEnum.Meter_States)
		@param State The state of the meter update
		@param Handler (optional) What happens once the update reaches its peak point (Max or Min)
	]]
	SetMeterUpdateType: (self: ServerAgentClass, Meter: string, Type: number, State: boolean, Handler: (() -> ())?) -> (),
	GetHitbox: (self: ServerAgentClass) -> (BasePart),
	GetEnergy: (self: ServerAgentClass) -> (number),
	GetStat: (self: ServerAgentClass, Stat: Stat) -> number,
	GetState: (self: ServerAgentClass) -> (State),
	GetSkillLevel: (self: ServerAgentClass, Name: AgentMovesetAbility) -> (number),
	GetMultBonus: (self: ServerAgentClass, Type: Element | AgentMovesetAbility) -> (number),

	--[[
		Change the state of the agent to the specified one, this limits/allows specific methods
		@param State The state to switch to, i. e. "Attacking", "Idle", "Stun";
		@param Time The time to remain in that state
	]]
	SwitchState: (self: ServerAgentClass, State: string, Time: number, Unaffected: boolean?) -> (),

	TakeDamage: (self: ServerAgentClass, Amount: number) -> (),
	Heal: (self: ServerAgentClass, Amount: number) -> (),
	SetMaxHealth: (self: ServerAgentClass, Amount: number, Fill: boolean?) -> (),
	GetHealth: (self: ServerAgentClass) -> (number, number),

	GiveUltimate: (self: ServerAgentClass, Amount: number) -> (),
	UseUltimate: (self: ServerAgentClass) -> (),
	GetUltimate: (self: ServerAgentClass) -> (number),

	GiveEnergy: (self: ServerAgentClass, Energy: number) -> (),
	UseEnergy: (self: ServerAgentClass, Energy: number) -> (),

	GetPivot: (self: ServerAgentClass) -> CFrame,

	--[[

		@param replicator_inside_call `boolean?` Whether this method is being called from the replicator
	]]
	PivotTo: (self: ServerAgentClass, Pivot: CFrame, replicator_inside_call: boolean?) -> (),
	IsAlive: (self: ServerAgentClass) -> boolean,

	AddGear: (self: ServerAgentClass, GearName: string) -> (),
	RemoveGear: (self: ServerAgentClass, GearName: string) -> (),
	GetGearManager: (self: ServerAgentClass) -> (ServerGearManager),

	AddTag: (self: ServerAgentClass, Tag: string, Time: number?, Replicate: boolean?) -> (),
	HasTag: (self: ServerAgentClass, Tag: string) -> (boolean),
	RemoveTag: (self: ServerAgentClass, Tag: string) -> (),

	--
	BindDrive: (self: ServerAgentClass, Drive: Drive) -> (),
	BindArtifact: (self: ServerAgentClass, Artifact: Artifact) -> (),

	--[[
		Add an effect to the player, effects are temporary/permanent buffs that are active for as long as specified (or match-long if undefined)
		@param Value The amount to modify, enter "30%" as a string to use percent, and flat number to use percents. This value gets converted if passed as percent.
		@param Type The stat or specific ability damage to buff
		@param Tag A tag to the effect, useful if later needs to be deleted (optional)
		@param Unique Delete all other effects with this tag (optional)
		@param Time How long the effect will last (optional)
		@return `EffectObject` The effect object. Effect.Remove() to delete.
	]]
	AddEffect: (self: ServerAgentClass, Data: EffectParameters) -> (EffectObject),

	--[[
		Get an effect from the player status by indexing it with its id
		@param Tag The tag to look the effect by
		@return `EffectObject` The effect object. Effect.Remove() to delete.
	]]
	GetEffect: (self: ServerAgentClass, Tag: string) -> (EffectObject),

	--[[
		Increase the amount of effects/charges an effect has
		@param Tag The tag to look the effect by
		@param Amount The amount to increase by
		@param RestartThread Whether to restart the timer or not, for timed effects.
	]]
	ChangeEffect: (self: ServerAgentClass, Tag: string, Amount: number?, RestartThread: boolean?) -> (EffectObject),

	--[[
		Refresh an agent buff effect, recreate it from scratch.
		@param Tag The tag to find and refresh. beware as repeated tags could cause trouble and refresh unwanted effects
	]]
	RefreshEffect: (self: ServerAgentClass, Tag: string) -> (),

	--[[
		Remove an agent buff effect
		@param Id The id to find and delete
	]]
	RemoveEffect: (self: ServerAgentClass, Id: number) -> (),
}

export type AgentItemsClass = {
	__Artifacts: {[number]: Artifact},
	__Drive: Drive,
	__Name: string,
	__Level: number,
	__Baked: {[Stat]: number},
	__Artifact_Count: {[string]: number},

	GetDriveStats: (self: AgentItemsClass) -> ({[Stat]: number}),
	GetArtifactStats: (self: AgentItemsClass) -> ({[Stat]: number}),

	GetTotalAddedStat: (self: AgentItemsClass, Key: Stat) -> (number),
	GetArtifactPieceEffects: (self: AgentItemsClass) -> ({[string]: number}),

	BindArtifact: (self: AgentItemsClass, Artifact: Artifact) -> (),
	BindDrive: (self: AgentItemsClass, Drive: Drive) -> (),
}

export type GearType = "AGENT" | "COMPANION"
export type GearObject = {
	Name: string,
	Amount: number,
	Type: GearType,
}

export type ServerGearManager = {
	__Items: AgentItemsClass,
	__Objects: {[string]: AgentArtifactClass & DriveObject},
	__Gears: {[string]: GearObject},
	__Gear_Calculations: {[string]: number},

	--[[
		Tries adding a gear item to the list of gear items
		@return `boolean` Whether the item was added to the list or not (false if the ItemLimit is reached).
	]]
	AddGear: (self: ServerGearManager, Gear: string) -> (boolean),
	AddObject: (self: ServerGearManager, Item: AgentArtifactClass) -> (),

	HasObject: (self: ServerGearManager, Name: string) -> (boolean),
	RemoveObject: (self: ServerGearManager, Item: AgentArtifactClass) -> (),

	--[[
		Removes an item from the itemlist
		@return `boolean` Whether or not the gear was fully removed from the class
	]]
	RemoveGear: (self: ServerGearManager, Gear: string) -> (boolean),

	--[[
		Executes a hook assigned to a specific event under the gear obtained
		@param HookId The hook event to trigger
		@param ProcessData The data related to the process running the hook
	]]

	RunHook: (self: ServerGearManager, HookId: number, Data: any) -> (),

	--[[
		Runs all the Effect Events for the artifacts/items equipped
		@param EventData : `ProcessEventData` The data for the effect process event
	]]
	RunEffectProcesses: (self: ServerGearManager, EventData: ProcessEventData) -> (),

	--[[
	]]

	RunEventHooks:(self: ServerGearManager, EventId: string, EventData: any) -> (),

	--[[
		Runs all the Hit Events for the artifacts/items equipped
		@param EventData : `ProcessEventData` The data for the hit process event
	]]
	RunHitProcesses: (self: ServerGearManager, State: HitProcessState, EventData: ProcessEventData) -> (),

	GetAddedGearStat: (self: ServerGearManager, Stat: Stat) -> (number),
}

export type ClientGearManager = {
	__Items: {string},
	__Gears: {[string]: GearObject},

	-- Currently unimplemented stubs on ClientGearClass (src/ReplicatedStorage/.../Agent/ClientGear.lua).
	Has: (self: ClientGearManager, ObjectName: string) -> (),
	AddItem: (self: ClientGearManager, Item: string) -> (),
	RemoveItem: (self: ClientGearManager, Item: string) -> (),

	--[[
		@return `boolean` Whether the item was added to the list or not (false if the ItemLimit is reached).
	]]
	AddGear: (self: ClientGearManager, Gear: string) -> (boolean),
	--[[
		@return `boolean` Whether or not the gear was fully removed from the class
	]]
	RemoveGear: (self: ClientGearManager, Gear: string) -> (boolean),

	GetAddedGearStat: (self: ClientGearManager, Stat: Stat) -> (number),
}

return 0
