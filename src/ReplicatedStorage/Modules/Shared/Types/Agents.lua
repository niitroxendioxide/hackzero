local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local Types = require(script.Parent)
local Heap = require(script.Parent.Parent.Utility.Heap)

export type Artifact = Types.PlayerArtifactData
export type Drive = Types.PlayerDriveData
export type Stat = Types.Stat
export type StatesClass = Types.StatesClass
export type StateEffect = Types.StateEffect
export type State = Types.State
export type AnimatorController = Types.AnimatorController
export type CharacterClass = Types.CharacterClass
export type CharacterStats = Types.CharacterStats
export type Heap = Heap.Heap
type Element = Types.Element
type AgentMovesetAbility = Types.AgentMovesetAbility
type Rig = Types.Rig
type Signal<T...> = Signal.ScriptSignal<T...>


export type Enemy = Types.ServerEnemyClass
export type ClientEnemy = Types.EnemyClass

export type ProcessEventData = {
	Agent: ServerAgentClass,
	Target: Enemy?,
	Critical: boolean?,
	Element: Element?,
	Total_Damage: number?,
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

	GetPieceCount: (self: AgentArtifactClass) -> (number),

	OnEffectProcess: (self: AgentArtifactClass, Event: (Data: ProcessEventData, PieceCount: number) -> ()) -> (),
	OnHitProcess: (self: AgentArtifactClass, State: HitProcessState, Event: (Data: ProcessEventData, PieceCount: number) -> (number, number)) -> (),
	GetEventFor: (self: AgentArtifactClass, EventName: string) -> ((Data: ProcessEventData) -> () | (Effect: Element, Data: ProcessEventData) -> ())?,
}
export type DriveObject = {}

export type AgentClass =  {
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
	GetId: (self: AgentClass) -> (number),

	Init: (self: AgentClass) -> (),
	Move: (self: AgentClass) -> (),
	Stop: (self: AgentClass) -> (),
	Look: (self: AgentClass, Direction: Vector3, Instant: boolean?, Bypass: boolean?) -> (),

	CanSwitch: (self: AgentClass) -> (boolean),
	GetPivot: (self: AgentClass) -> CFrame,
	GetModel: (self: AgentClass) -> Rig,
	PivotTo: (self: AgentClass) -> CFrame,
	IsMoving: (self: AgentClass) -> boolean,
	IsAlive: (self: AgentClass) -> boolean,

	--[[
		Walk forward for the specified time
		@param Time the time to walk for
	]]
	Walk: (self: AgentClass, Time: number) -> (),
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

	GiveEnergy: (self: AgentClass, Amount: number) -> (),
	SetVisible: (self: AgentClass, State: boolean?) -> (),
	SetEnergy: (self: AgentClass, Energy: number) -> (),

	AddEffect: (self: AgentClass, Effect: EffectParameters) -> StateEffect,
	AddTrackToState: (self: AgentClass, State: string, Track: AnimationTrack, DisableTime: number) -> (),
	GetEffect: (self: AgentClass, Name: string) -> StateEffect,
	RemoveEffect: (self: AgentClass, Id: number) -> (),

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



type AgentMeter = {
		Value: number,
		Max: number,

		Name: string,
		FillSpeed: number,
		EmptySpeed: number,
		LastUpdate: number,

		Fill: boolean,
		Empty: boolean,
}
export type AgentStatusClass = {
	__Ultimate: number,
	__Energy: number,
	__Health: number,
	__Max_Health: number,
	__Base_Stats: CharacterStats,
	__Alive: boolean,
	__Total_Effects: Heap,
	__Meters: {AgentMeter},

	__Artifact_Set: {},
	__Card_Set: nil,
	__Effects: {EffectObject},


	CreateMeter: (self: AgentStatusClass, Name: string, Data: {Max: number?, EmptySpeed: number?, FillSpeed: number?, Id: number}) -> (),
	UpdateMeter: (self: AgentStatusClass, Name: string, Amount: number) -> (),
	GetAllMeters: (self: AgentStatusClass) -> ({AgentMeter}),
	RemoveMeter: (self: AgentStatusClass, Name: string) -> (),
	SetMeterUpdateType: (self: AgentStatusClass, Meter: string, Type: number, State: boolean, Handler: (() -> ())?) -> (),

	GetStat: (self: AgentStatusClass, Name: Stat) -> (number),
	Update: (self: AgentStatusClass, delta: number) -> (),

	IsAlive: (self: AgentStatusClass) -> (boolean),
	Revive: (self: AgentStatusClass) -> (),
	Damage: (self: AgentStatusClass, Amount: number) -> (),
	Heal: (self: AgentStatusClass, Amount: number) -> (),
	GetHealth: (self: AgentStatusClass) -> (number, number),
	GetEnergy: (self: AgentStatusClass) -> (number),

	SetEnergy: (self: AgentStatusClass, Energy: number) -> (),
	UseEnergy: (self: AgentStatusClass, EnergyUsed: number) -> (),
	GiveEnergy: (self: AgentStatusClass, EnergyGiven: number) -> (),

	AddEffect: (self: AgentStatusClass, EffectParameters) -> (EffectObject),
	GetEffect: (self: AgentStatusClass, string) -> (EffectObject),
	GetStatEffects: (self: AgentStatusClass, Stat) -> (number),
	RemoveEffect: (self: AgentStatusClass, Id: number) -> (),

	GetArtifactBonus: (self: AgentStatusClass, Type: string) -> (number),
	GetDriveBonus: (self: AgentStatusClass, Type: string) -> (),
	GetMultBonus: (self: AgentStatusClass, Name: string) -> (),

	GetUltimate: (self: AgentStatusClass) -> (number),
	SetUltimate: (self: AgentStatusClass, Value: number) -> (number),
	UseUltimate: (self: AgentStatusClass, Mods: {}?) -> (),
	GiveUltimate: (self: AgentStatusClass, Amount: number) -> (),
}


-- [[Server data]]
export type EffectParameters = {Type: (Stat & AgentMovesetAbility)?, Value: (number | string)?, Time: number?, Tag: string, Unique: boolean?, Callback: ((Id: number) -> ())?}
export type EffectObject = {Remove: () -> (), Id: number, Value: number, Type: Stat & AgentMovesetAbility, Tag: string?, Time: number?, Created: number}
export type ServerCharacterClass = {
	__MovementVelocity: Vector3,
	__SurfaceVelocity: Vector3,
	__LastMovementVelocity: Vector3,
	__Velocity: Vector3,
	__ActiveThread: thread?,
	__PhysicsSpeed: number,
	__Moving: boolean,
	__Active: boolean,
	__MovementAcceleration: number,
	__Linear_Movements: {},
	__Forward_Velocities: {},

	Name: string,
	States: StatesClass,

	Init: (self: ServerCharacterClass) -> (),

	Stop: (self: ServerCharacterClass) -> (),
	Move: (self: ServerCharacterClass) -> (),
	Rotate: (self: ServerCharacterClass) -> (),

	GetPivot: (self: ServerCharacterClass) -> CFrame,
	PivotTo: (self: ServerCharacterClass, Pivot: CFrame) -> (),

	ApplyForwardImpulse: (self: ServerCharacterClass, Power: number, FadeOutTime: number) -> (),
	AddLinearMovement: (self: ServerCharacterClass, Direction: Vector3, Time: number) -> (),

	RemoveForwardImpulse:  (self: ServerCharacterClass, Object: {}) -> (),
}


--[[ CHARACTER CONTROLLERS ]]
export type AssistStruct = {
	TargetId: number,
	Accepted: Signal<nil>,
	Time: number,
}

type SkillLevels = {
		Basic_Attack: number,
		Ultimate: number,
		Special: number,
	}

export type ServerAgentClass = {
	Name: string,

	__Level: number,
	__User: number,
	__Main_Thread: thread,
	__Player_Assigned: Player,
	__Status: AgentStatusClass,
    __Items: AgentItemsClass,
	__Skill_Levels: SkillLevels,
	__Last_Skill_Cast: number,
	__Last_Hit_Time: number,
	__Current_Target: {Data: AssistStruct, Thread: thread}?,
	__Gear: ServerGearManager,

	__Active: boolean,
	__Character: ServerCharacterClass,

	GetId: (self: ServerAgentClass) -> (number),
	Init: (self: ServerAgentClass) -> (),
	Stop: (self: ServerAgentClass) -> (),
	Move: (self: ServerAgentClass) -> (),
	Rotate: (self: ServerAgentClass, Angle: number) -> (),

	IsBeingAttacked: (self: ServerAgentClass) -> (boolean),
	Hit: (self: ServerAgentClass, Caster: Enemy, Time: number) -> (),
	GetMarkedTarget: (self: ServerAgentClass) -> (AssistStruct?),

	UpdateMeter: (self: ServerAgentClass, Name: string, Amount: number) -> (),
	GetMeter: (self: ServerAgentClass, Name: string) -> (number, number),

	GetCurrentSkill: (self: ServerAgentClass) -> (string?),

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
	]]
	Walk: (self: ServerAgentClass, Time: number) -> (),

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
	GetState: (self: ServerAgentClass) -> (),
	GetMultBonus: (self: ServerAgentClass, Type: Element | AgentMovesetAbility) -> (number),
	GetSkillLevel: (self: ServerAgentClass, Name: AgentMovesetAbility) -> (),

	--[[
		Change the state of the agent to the specified one, this limits/allows specific methods
		@param State The state to switch to, i. e. "Attacking", "Idle", "Stun";
		@param Time The time to remain in that state
	]]
	SwitchState: (self: ServerAgentClass, State: string, Time: number, Unaffected: boolean?) -> (),

	TakeDamage: (self: ServerAgentClass, Amount: number) -> (),
	Heal: (self: ServerAgentClass, Amount: number) -> (),
	GetHealth: (self: ServerAgentClass) -> (number, number),

	GiveUltimate: (self: ServerAgentClass, Amount: number) -> (),
	UseUltimate: (self: ServerAgentClass) -> (),
	GetUltimate: (self: ServerAgentClass) -> (number),

	GiveEnergy: (self: ServerAgentClass, Energy: number) -> (),
	UseEnergy: (self: ServerAgentClass, Energy: number) -> (),

	GetPivot: (self: ServerAgentClass) -> CFrame,
	PivotTo: (self: ServerAgentClass, Pivot: CFrame) -> (),
	IsAlive: (self: ServerAgentClass) -> boolean,

	AddGear: (self: ServerAgentClass, GearName: string) -> (),
	RemoveGear: (self: ServerAgentClass, GearName: string) -> (),
	GetGearManager: (self: ServerAgentClass) -> (ServerGearManager),

	AddTag: (self: ServerAgentClass, Tag: string, Time: number?) -> (),
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
	GetEffect: (self: ServerAgentClass, Tag: string) -> (EffectObject?),
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

export type GearObject = {
	Name: string,
	Amount: number,
}

export type ServerGearManager = {
	__Items: AgentItemsClass,
	__Objects: {[string]: AgentArtifactClass & DriveObject},
	__Gears: {[string]: GearObject},

	--[[
		Tries adding a gear item to the list of gear items, returns false if the ItemLimit is Reached
		@return `boolean` Whether the item was added to the list or not.
	]]
	AddGear: (self: ServerGearManager, Gear: string) -> (),
	AddObject: (self: ServerGearManager, Item: AgentArtifactClass) -> (),

	HasObject: (self: ServerGearManager, Name: string) -> (boolean),
	RemoveObject: (self: ServerGearManager, Item: AgentArtifactClass) -> (),

	--[[
		Removes an item from the itemlist, returns true if the item was succesfully deleted
		@return `boolean` Whether or not the gear was fully removed from the class
	]]
	RemoveGear: (self: ServerGearManager, Gear: string) -> (),

	--[[
		Runs all the Effect Events for the artifacts/items equipped
		@param EventData : `ProcessEventData` The data for the effect process event
	]]
	RunEffectProcesses: (self: ServerGearManager, EventData: ProcessEventData) -> (),

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

	Has: (self: ClientGearManager, ObjectName: string) -> (),
	AddItem: (self: ClientGearManager, Item: string) -> (),
	AddGear: (self: ClientGearManager, Gear: string) -> (),

	RemoveItem: (self: ClientGearManager, Item: string) -> (),
	RemoveGear: (self: ClientGearManager, Gear: string) -> (),

	GetAddedGearStat: (self: ClientGearManager, Stat: Stat) -> (number),
}


return{}