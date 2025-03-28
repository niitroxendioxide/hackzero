--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- [[ Other ]]

--// B rank, A rank, S rank
export type Rarity = 'Rare' | 'Legendary' | 'Mythical'

-- [[ Character Controlling ]]
export type Rig = Model & {
	Humanoid: Humanoid,

	HumanoidRootPart: BasePart,
	LeftUpperArm: BasePart,
	LeftLowerArm: BasePart,
	LeftHand: BasePart,
	RightUpperArm: BasePart,
	RightLowerArm: BasePart,
	RightHand: BasePart,
	LowerTorso: BasePart,
	UpperTorso: BasePart,
	Head: BasePart,
	LeftUpperLeg: BasePart,
	LeftLowerLeg: BasePart,
	LeftFoot: BasePart,
	RightUpperLeg: BasePart,
	RightLowerLeg: BasePart,
	RightFoot: BasePart,
}

export type AppearanceController = {
	__Visible: boolean,
	__Model: Rig,
	__TransparencyValues: {[BasePart]: number},
	__Trove: {},
	
	SetVisible: (self: AppearanceController, State: boolean) -> (),
	JoinTo: (self: AppearanceController, BasePart: BasePart) -> (),
	
	Destroy: (self: AppearanceController) -> (),
}

export type AnimatorController = {
	__Character: CharacterClass,
	__Tracks: {[string]: AnimationTrack},
	__Directory: string,
	__IsMoving: boolean,
	
	Init: (self: AnimatorController) -> (),
	Play: (self: AnimatorController, Track: string) -> (),
	GetTrack: (self: AnimatorController, Track: string) -> AnimationTrack,
}

export type PhysicsController = {
	__PhysicsSpeed: number,
	__Active: boolean,
	__Height: number,
	__Position: Vector3,
	__Normal: Vector3,
	__Rotation: Vector3,
	__RotationGoal: Vector3,
	__Velocity: Vector3,
	__MovementVelocity: Vector3,
	__Moving: boolean,
	
	__Collider: BasePart,
	
	
	Run: (self: PhysicsController) -> (),
	Pause: (self: PhysicsController) -> (),
	
	CreateCollider: (self: PhysicsController) -> (),
	GetCollider: (self: PhysicsController) -> BasePart,
	
	PivotTo: (self: PhysicsController, PivotCFrame: CFrame) -> (),
	GetPivot: (self: PhysicsController) -> CFrame,
	
	Rotate: (self: PhysicsController, Direction: Vector3) -> (),
	SetMovementVelocity: (self: PhysicsController, Velocity: Vector3) -> (),
	StopMovement: (self: PhysicsController) -> (),
	ApplyImpulse: (self: PhysicsController, Velocity: Vector3) -> (),
	Update: (self: PhysicsController, Delta: number) -> (),
}

export type CharacterClass = {
	Name: string,
	
	__Controller: PhysicsController,
	__Appearance: AppearanceController,
	__Animator: AnimatorController,
	__States: StatesClass,
	
	Init: (self: CharacterClass) -> (),
	Move: (self: CharacterClass) -> (),
	Stop: (self: CharacterClass) -> (),
	Look: (self: CharacterClass) -> (),
	Knock: (self: CharacterClass) -> (),
	
	GetPivot: (self: CharacterClass) -> CFrame,
	GetModel: (self: CharacterClass) -> Rig,
	PivotTo: (self: CharacterClass) -> CFrame,
	IsMoving: (self: CharacterClass) -> boolean,
	GetMovementSpeed: (self: CharacterClass) -> number,
	
	SetKey: (self: CharacterClass, Key: string, State: boolean) -> (),
	GetKey: (self: CharacterClass, Key: string) -> boolean,
	
	GetState: (self: CharacterClass) -> State,
	SetVisible: (self: CharacterClass, State: boolean?) -> (),
	
	AddEffect: (self: StatesClass, Name: string, Value: number, Time: number?) -> StateEffect,
	GetEffect: (self: StatesClass, Name: string) -> StateEffect,
}

export type StateEffect = {
	Name: string,
	Value: number,
	
	Time: number,
	Started: number,
}

export type State = 'Idle' | 'Attacking' | 'Dashing' | 'Stunned' | 'Frozen'
export type StatesClass = {
	__Effects: {},
	__Character: string,
	__Keys: {Running: boolean, Sprinting: boolean},
	__State: State,
	
	GetKey: (self: StatesClass, Key: string) -> boolean,
	SetKey: (self: StatesClass, Key: string, State: boolean) -> (),
	
	GetSpeed: (self: StatesClass) -> number,
	GetStats: (self: StatesClass) -> CharacterStats,
	GetLastChangeTime: (self: StatesClass) -> number,
	
	AddEffect: (self: StatesClass, Name: string, Value: number, Time: number?) -> StateEffect,
	GetEffect: (self: StatesClass, Name: string) -> StateEffect,
}

export type AgentClass =  {
	Name: string,
	
	Init: (self: AgentClass) -> (),
	Move: (self: AgentClass) -> (),
	Stop: (self: AgentClass) -> (),
	Look: (self: AgentClass) -> (),

	GetPivot: (self: AgentClass) -> CFrame,
	GetModel: (self: AgentClass) -> Rig,
	PivotTo: (self: AgentClass) -> CFrame,
	IsMoving: (self: AgentClass) -> boolean,
	Walk: (self: AgentClass, Time: number) -> (),
	 
	

	SetKey: (self: AgentClass, Key: string, State: boolean) -> (),
	GetKey: (self: AgentClass, Key: string) -> boolean,

	GetHealth: (self: AgentClass) -> (number, number),
	GetStat: (self: AgentClass, Stat: Stat) -> number,
	GetState: (self: AgentClass) -> State,
	GetEnergy: (self: AgentClass) -> (number),
	SetVisible: (self: AgentClass, State: boolean?) -> (),

	AddEffect: (self: StatesClass, Name: string, Value: number, Time: number?) -> StateEffect,
	GetEffect: (self: StatesClass, Name: string) -> StateEffect,
	
	GetAnimator: (self: AgentClass) -> AnimatorController,
	SwitchState: (self: AgentClass, State: State, Time: number) -> (),
	
	TakeDamage: (self: AgentClass, Amount: number) -> (),
	Heal: (self: AgentClass, Amount: number) -> (),
	
	__Character: CharacterClass,
	__Status: AgentStatusClass
}

export type AgentStatusClass = {
	GetStat: (self: AgentStatusClass, Name: Stat) -> (number),
	Update: (self: AgentStatusClass, delta: number) -> (),
	

	Damage: (self: AgentStatusClass, Amount: number) -> (),
	Heal: (self: AgentStatusClass, Amount: number) -> (),
	GetHealth: (self: AgentStatusClass) -> (number, number),
	
	AddEffect: (self: AgentStatusClass, Effect) -> (),
	GetEffect: (self: AgentStatusClass, Effect) -> (),
	
	GetArtifactBonus: (self: AgentStatusClass, Type: string) -> (number),
	GetWeaponBonus: (self: AgentStatusClass, Type: string) -> (),
	GetMultBonus: (self: AgentStatusClass, Name: string) -> (),
}

-- [[ INPUTS ]]
export type KeybindData = {
	Release: boolean?,
	
	Callback: (any) -> any,
}

export type BoundKeybind = {
	Key: string,
	Held: boolean,
	Release: boolean,
	Time: number,

	Callback: (any) -> any,
}

-- [[ DATA ]]
export type Role = 'Attack' | 'Element' | 'Support' | 'Stun'
export type Stat = 'Health' | 'Attack' | 'Defense' | 'Critical_Rate' | 'Critical_Damage' | 'Penetration' | 'Pen_Ratio' | 'Daze' | 'Energy_Regeneration' | 'Affliction_Aptitude' | 'Affliction_Facility'
export type Element = 'Physical' | 'Energy' | 'Fire' | 'Ice' | 'Electric' | 'Wind' | 'Rock'
export type CharacterStats = {[Stat]: number, Jog_Speed: number, Sprint_Speed: number, Walk_Speed: number}

export type EnemyStats = {
	[Stat]: number, 
	Weakness: {[number]: Element}, 
	Strength: {[number]: Element}, 
	Movement_Speed: number
}

export type CharacterData = {
	Display_Name: string,
	Element: Element,
	Role: Role,
	Appearance: CharacterAppearanceData,
	
	Stats: CharacterStats,
	Level_Stats: {[Stat]: number},
}

export type CharacterAppearanceData = {
	Height: number,
}

-- [[Server data]]

export type ServerCharacterClass = {
	Name: string,
	States: StatesClass,
	
	Init: (self: ServerCharacterClass) -> (),
	
	Stop: (self: ServerCharacterClass) -> (),
	Move: (self: ServerCharacterClass) -> (),
	Rotate: (self: ServerCharacterClass) -> (),
	
	GetPivot: (self: ServerCharacterClass) -> CFrame,
	PivotTo: (self: ServerCharacterClass, Pivot: CFrame) -> (),
}

export type ServerAgentClass = {
	Name: string,
	
	Init: (self: ServerAgentClass) -> (),
	Stop: (self: ServerAgentClass) -> (),
	Move: (self: ServerAgentClass) -> (),
	Rotate: (self: ServerAgentClass, Angle: number) -> (),
	
	ApplyImpulse: (self: ServerAgentClass, Velocity: Vector3) -> (),
	SetKey: (self: ServerAgentClass, Key: string, Value: any) -> (),
	GetKey: (self: ServerAgentClass, Velocity: Vector3) -> (),
	Walk: (self: ServerAgentClass, Time: number) -> (),

	GetHitbox: (self: ServerAgentClass) -> (BasePart),
	GetEnergy: (self: ServerAgentClass) -> (number),
	GetStat: (self: ServerAgentClass, Stat: Stat) -> number,
	GetState: (self: ServerAgentClass) -> (),
	SwitchState: (self: ServerAgentClass, State: string, Time: number) -> (),
	
	TakeDamage: (self: ServerAgentClass, Amount: number) -> (),
	Heal: (self: ServerAgentClass, Amount: number) -> (),
	GetHealth: (self: ServerAgentClass) -> (number, number),
	
	GetPivot: (self: ServerAgentClass) -> CFrame,
	PivotTo: (self: ServerAgentClass, Pivot: CFrame) -> (),
}


--[[ CHARACTER CONTROLLERS ]]
export type AgentMovesetAbility = "Basic Attack" | "Special Attack" | "Chain Attack" | "Dodge" | "Dodge Counter" | "Quick Assist" | "Ultimate" | "Passive"

export type MovesetClass = {
	__Assigned: {[AgentMovesetAbility]: AbilityClass},
	
	--
	Assign: (self: MovesetClass, Key: string, Ability: AbilityClass) -> (),
	Verify: (self: MovesetClass, Agent: AgentClass, Type: string) -> boolean,
	
	Begin: (self: MovesetClass, Key: AgentMovesetAbility, Agent: AgentClass) -> (),
	
	GetInfoForSkill: (self: MovesetClass, Name: string) -> {},
	SetAbilityInformation: (self: MovesetClass, Data: {}) -> (),
}

export type SequenceFrames = {{number | (self: Sequence) -> ()}}
export type Sequence = {
	__cache: {[any]: any},
	__frames: SequenceFrames,

	--
	Start: (self: Sequence) -> Sequence,
	Pause: (self: Sequence) -> Sequence,
	Destroy: (self: Sequence) -> (),
	GetSpeed: (self: Sequence) -> (),

	--
	Update: (self: Sequence) -> (),
	After: (self: Sequence, fn: (self: Sequence) -> ()) -> Sequence,
}

export type AbilityClass = {
	__Cache: {},
	__Signal: RBXScriptSignal,
	
	PlayAnimation: (self: AbilityClass, Agent: AgentClass, Track: string, Data: {Fade: number, Speed: number, Weight: number}) -> (),
	CreateHitbox: (self: AbilityClass, Agent: Types.AgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.ServerEnemyClass) -> ()) -> (),
	
	Save: (self: AbilityClass, Agent: AgentClass, Key: string, Value: any) -> (),
	Get: (self: AbilityClass, Agent: AgentClass, Key: string) -> any,
	Increase: (self: AbilityClass, Agent: Types, Key: string, Data: {Rate: number, Limit: number}?) -> (),
	
	Play: (self: AbilityClass, Agent: AgentClass, Type: string, State: 'Begin' | 'End', Other: {any}) -> (),
	Begin: (self: AbilityClass, Agent: AgentClass, SequenceFrames: SequenceFrames) -> (),
	
	FromData: (self: AbilityClass, Key: string) -> (any),
	SetData: (self: AbilityClass, Data: {}) -> (),
}

export type ServerAbilityClass = {
	__Cache: {},
	__Signal: RBXScriptSignal,

	PlayAnimation: (self: ServerAbilityClass, Agent: AgentClass, Track: string, Data: {Fade: number, Speed: number, Weight: number}) -> (),
	CreateHitbox: (self: ServerAbilityClass, Agent: Types.AgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: Types.ServerEnemyClass) -> ()) -> (),

	Save: (self: ServerAbilityClass, Agent: AgentClass, Key: string, Value: any) -> (),
	Get: (self: ServerAbilityClass, Agent: AgentClass, Key: string) -> any,
	Increase: (self: ServerAbilityClass, Agent: Types, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	Play: (self: ServerAbilityClass, Agent: AgentClass, Type: string, State: 'Begin' | 'End', Other: {any}) -> (),
	Begin: (self: ServerAbilityClass, Agent: AgentClass, SequenceFrames: SequenceFrames) -> (),
	
	Hit: (self: ServerAbilityClass, Agent: AgentClass, Enemy: ServerEnemyClass, Hit: HitEnemyData) -> (number),
	
	FromData: (self: ServerAbilityClass, Key: string) -> (any),
	SetData: (self: ServerAbilityClass, Data: {}) -> (),
}

export type EnemyClass = {
	__Status: EnemyStatus,
	
	__Health: Fusion.Value,
	__Daze: Fusion.Value,
	__Affliction: Fusion.Value,
	__Affliction_Type: Fusion.Value,

	Init: (self: EnemyClass, Key: number) -> (),
	Move: (self: EnemyClass, Direction: Vector3) -> (),

	PivotTo: (self: EnemyClass, At: CFrame) -> (),

	GetState: (self: EnemyClass) -> State,
	GetPivot: (self: EnemyClass) -> CFrame,
	GetHitbox: (self: EnemyClass) -> BasePart,	
	IsMoving: (self: EnemyClass) -> EnemyClass,
	Rotate: (self: EnemyClass, Direction: Vector3) -> (),

	SwitchState: (self: EnemyClass, State: string, Time: number) -> (),
}

export type ServerEnemyClass = {
	__Status: EnemyStatus,
	
	Init: (self: ServerEnemyClass, Key: number) -> (),
	Move: (self: ServerEnemyClass, Direction: Vector3) -> (),
	
	GetState: (self: ServerEnemyClass) -> State,
	GetPivot: (self: ServerEnemyClass) -> CFrame,
	GetHitbox: (self: ServerEnemyClass) -> BasePart,	
	GetTarget: (self: ServerEnemyClass) -> ServerAgentClass,
	TimeSinceLastPivot: (self: ServerEnemyClass) -> number,
	
	Rotate: (self: ServerEnemyClass, Direction: Vector3) -> (),
	PivotTo: (self: ServerEnemyClass, At: CFrame) -> (),
	
	SwitchState: (self: ServerEnemyClass, State: string, Time: number) -> (),
}

export type EnemyStatus = {
	EnteredDazeState: RBXScriptSignal,
	
	__State: State,
	__Level: number,
	__Stats: EnemyStats,
	__Effects: {},
	__AfflictionMeter: {[Element]: number},
	__AfflictionTotalDamage: {[Element]: number?},
	__Health: number,
	__Daze: number,
	
	--
	Damage: (self: EnemyStatus, Damage: number) -> (),
	Heal: (self: EnemyStatus, Amount: number) -> (),
	Daze: (self: EnemyStatus, Daze: number) -> (),
	
	GetHealth: (self: EnemyStatus) -> number,
	IsAlive: (self: EnemyStatus) -> (boolean),
	IsKnocked: (self: EnemyStatus) -> (boolean),
	SwitchState: (self: EnemyStatus, State: State) -> (),
	
	GetStat: (self: EnemyStatus) -> (number),
	GetDamageTakenMultiplier: (self: EnemyStatus) -> (number),
	GetResistanceMultiplier: (self: EnemyStatus) -> (number),
	GetElementResistances: (self: EnemyStatus, Element: Element) -> (number, number),
	
	FillAffliction: (self: EnemyStatus, Type: Element, Amount: number, Damage: number?) -> (),
	ResetAffliction: (self: EnemyStatus, Type: Element) -> (),
	GetAffliction: (self: EnemyStatus, Type: Element) -> (number),
	GetAfflictionStackedDamage: (self: EnemyStatus, Type: Element) -> (number),
	EnterDazedState: (self: EnemyStatus, fn: (DazeValue: number) -> ()) -> (),
}

export type HitEnemyData = {
	Damage: number,
	Stun: number,
	Affliction: (Element | 'None')?,
	Attack_Type: 'Basic' | 'Special' | 'Ultimate',
	Affliction_Buildup: number,
	
	Knockback: {number | number | number},
}

export type AbilityHitRequest = HitEnemyData & {

}

export type List<T> = {[number]: T}

--
local Fusion = require(ReplicatedStorage.Modules.Client.Libraries.Fusion)

export type UIComponent = {
	__Name: string,
	__Group: string,
	__Scope: Fusion.Scope,
	__Main_Frame: CanvasGroup | Frame,
	
	GetScope: (self: UIComponent) -> (Fusion.Scope),
	GetFrame: (self: UIComponent) -> CanvasGroup | Frame,
	
	Init: (self: UIComponent) -> (),
	Link: (self: UIComponent, Object: CanvasGroup | Frame) -> (),
	Set: (self: UIComponent, State: boolean) -> (),
}

export type Artifact_Substat = "Health%" | "Health" | "Attack" | "Attack%" | "Defense" | "Defense%" | "Crit_Rate" | "Crit_Damage" | "Penetration" | "Affliction_Aptitude"

export type Artifact_Data = {
	Name: string,

	--
	Piece_Effects: {
		Two_Piece: {
			[Stat]: number,
		},
		
		Four_Piece: {
			[Stat]: number,
		}
	},
	
	Piece_Descriptions: {
		Two_Piece: string,
		Four_Piece: string,
	}
}

export type Process_Event_Data = {
	Agent: ServerAgentClass,
	Target: ServerEnemyClass,
	Critical: boolean,
	
}

export type Substats = {
	[Artifact_Substat]: number,
}
export type Hit_Process_State = "Before" | "After"
export type Artifact_Class = {
	Slot: number,
	Level: number,
	Rarity: Rarity,
	
	--
	Main_Stat: {Stat | number},
	Stats: Substats,
	
	-- #Privates
	__Events: {},
	__Count: number,
	
	--
	Extend: (self: Artifact_Class, Slot: number, Level: number, Mainstat: {Stat | number}, Substats: Substats) -> Artifact_Class,
	
	GetPieceCount: (self: Artifact_Class) -> (number),
	
	OnEffectProcess: (self: Artifact_Class, Event: (Effect: Element, Data: Process_Event_Data) -> ()) -> (),
	OnHitProcess: (self: Artifact_Class, State: Hit_Process_State, Event: (Data: Process_Event_Data) -> (number, number)) -> (),
}

return false