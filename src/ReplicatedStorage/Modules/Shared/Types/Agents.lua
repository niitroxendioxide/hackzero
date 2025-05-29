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

export type AgentClass =  {
	Name: string,
	PlayerId: number,

	__Level: number,
	__User: number,
	__Player_Assigned: Player,
	__Items: AgentItemsClass,
	GetId: (self: AgentClass) -> (number),

	Init: (self: AgentClass) -> (),
	Move: (self: AgentClass) -> (),
	Stop: (self: AgentClass) -> (),
	Look: (self: AgentClass, Direction: Vector3, Instant: boolean?, Bypass: boolean?) -> (),

	GetPivot: (self: AgentClass) -> CFrame,
	GetModel: (self: AgentClass) -> Rig,
	PivotTo: (self: AgentClass) -> CFrame,
	IsMoving: (self: AgentClass) -> boolean,

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

	GiveEnergy: (self: AgentClass, Amount: number) -> (),
	SetVisible: (self: AgentClass, State: boolean?) -> (),
	SetEnergy: (self: AgentClass, Energy: number) -> (),

	AddEffect: (self: AgentClass, Effect: EffectParameters) -> StateEffect,
	AddTrackToState: (self: AgentClass, State: string, Track: AnimationTrack, DisableTime: number) -> (),
	GetEffect: (self: AgentClass, Name: string) -> StateEffect,
	RemoveEffect: (self: AgentClass, Id: number) -> (),

	GetAnimator: (self: AgentClass) -> AnimatorController,

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


export type AgentStatusClass = {
	__Ultimate: number,
	__Energy: number,
	__Health: number,
	__Max_Health: number,
	__Base_Stats: CharacterStats,
	__Total_Effects: Heap,

	__Artifact_Set: {},
	__Card_Set: nil,
	__Effects: {EffectObject},

	GetStat: (self: AgentStatusClass, Name: Stat) -> (number),
	Update: (self: AgentStatusClass, delta: number) -> (),


	Damage: (self: AgentStatusClass, Amount: number) -> (),
	Heal: (self: AgentStatusClass, Amount: number) -> (),
	GetHealth: (self: AgentStatusClass) -> (number, number),
	GetEnergy: (self: AgentStatusClass) -> (number),

	SetEnergy: (self: AgentStatusClass, Energy: number) -> (),
	UseEnergy: (self: AgentStatusClass, EnergyUsed: number) -> (),
	GiveEnergy: (self: AgentStatusClass, EnergyGiven: number) -> (),

	AddEffect: (self: AgentStatusClass, EffectParameters) -> (EffectObject),
	GetEffect: (self: AgentStatusClass, string) -> (EffectObject),
	GetStatEffects: (self: AgentStatusClass, Stat) -> (),
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
export type EffectParameters = {Type: Stat & AgentMovesetAbility, Value: number | string, Time: number, Tag: string, Unique: boolean?, Callback: ((Id: number) -> ())?}
export type EffectObject = {Remove: () -> (), Id: number, Value: number, Type: Stat & AgentMovesetAbility, Tag: string?, Time: number?, Created: number}
export type ServerCharacterClass = {
	Name: string,
	States: StatesClass,

	Init: (self: ServerCharacterClass) -> (),

	Stop: (self: ServerCharacterClass) -> (),
	Move: (self: ServerCharacterClass) -> (),
	Rotate: (self: ServerCharacterClass) -> (),

	GetPivot: (self: ServerCharacterClass) -> CFrame,
	PivotTo: (self: ServerCharacterClass, Pivot: CFrame) -> (),

	AddLinearMovement: (self: ServerCharacterClass, Direction: Vector3, Time: number) -> (),
}


--[[ CHARACTER CONTROLLERS ]]
export type AssistStruct = {
	TargetId: number,
	Accepted: Signal<nil>,
	Time: number,
}

export type ServerAgentClass = {
	Name: string,

	__Level: number,
	__User: number,
	__Main_Thread: thread,
	__Player_Assigned: Player,
	__Status: AgentStatusClass,
    __Items: AgentItemsClass,
	__Current_Target: {Data: AssistStruct, Thread: thread}?,

	__Active: boolean,
	__Character: ServerCharacterClass,

	GetId: (self: ServerAgentClass) -> (number),
	Init: (self: ServerAgentClass) -> (),
	Stop: (self: ServerAgentClass) -> (),
	Move: (self: ServerAgentClass) -> (),
	Rotate: (self: ServerAgentClass, Angle: number) -> (),

	GetMarkedTarget: (self: ServerAgentClass) -> (AssistStruct?),

	--[[
		Set to nil for no target
		@param TargetId Number id for enemy
		@param Time how long prompt lasts
	]]
	MarkTarget: (self: ServerAgentClass, TargetId: number?, Time: number?) -> (AssistStruct),

	ApplyImpulse: (self: ServerAgentClass, Velocity: Vector3) -> (),
	SetKey: (self: ServerAgentClass, Key: string, Value: any) -> (),
	GetKey: (self: ServerAgentClass, Velocity: Vector3) -> (),

	--[[
		Walk forward for the specified time
		@param Time the time to walk for
	]]
	Walk: (self: ServerAgentClass, Time: number) -> (),

	GetHitbox: (self: ServerAgentClass) -> (BasePart),
	GetEnergy: (self: ServerAgentClass) -> (number),
	GetStat: (self: ServerAgentClass, Stat: Stat) -> number,
	GetState: (self: ServerAgentClass) -> (),
	GetMultBonus: (self: ServerAgentClass, Type: Element | AgentMovesetAbility) -> (number),

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

	AddTag: (self: ServerAgentClass, Tag: string, Time: number) -> (),
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

    GetDriveStats: (self: AgentItemsClass) -> ({[Stat]: number}),
    GetArtifactStats: (self: AgentItemsClass) -> ({[Stat]: number}),

    GetTotalAddedStat: (self: AgentItemsClass, Key: Stat) -> (number),

    BindArtifact: (self: AgentItemsClass, Artifact: Artifact) -> (),
    BindDrive: (self: AgentItemsClass, Drive: Drive) -> (),
}

return{}