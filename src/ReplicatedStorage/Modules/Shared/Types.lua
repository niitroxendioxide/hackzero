--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Fusion = require(ReplicatedStorage.Modules.Client.Libraries.Fusion)
local _GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)

-- [[ Other ]]

--// B rank, A rank, S rank
export type Tier = 'Rare' | 'Legendary' | 'Mythical' | 'Common'

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

	GetSpeed: (self: StatesClass, boolean) -> number,
	GetStats: (self: StatesClass) -> CharacterStats,
	GetLastChangeTime: (self: StatesClass) -> number,

	AddEffect: (self: StatesClass, Name: string, Value: number, Time: number?) -> StateEffect,
	GetEffect: (self: StatesClass, Name: string) -> StateEffect,
}

export type GenericClass = {
	Name: string,

	BlockRotation: (self: GenericClass, Time: number) -> (),
	GetId: (self: GenericClass) -> (number),
	GetEnergy: (self: GenericClass) -> (number),

	AddTag: (self: GenericClass, Tag: string, Time: number) -> (),
	RemoveTag: (self: GenericClass, Tag: string) -> (),
	HasTag: (self: GenericClass, Tag: string) -> (boolean),

	GetModel: (self: GenericClass) -> Model,
}

export type AgentClass =  {
	Name: string,
	PlayerId: number,

	__User: number,
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

	GetHealth: (self: AgentClass) -> (number, number),
	GetStat: (self: AgentClass, Stat: Stat) -> number,
	GetState: (self: AgentClass) -> State,
	GetEnergy: (self: AgentClass) -> (number),

	GiveEnergy: (self: AgentClass, Amount: number) -> (),
	SetVisible: (self: AgentClass, State: boolean?) -> (),
	SetEnergy: (self: AgentClass, Energy: number) -> (),

	AddEffect: (self: AgentClass, Name: string, Value: number, Time: number?) -> StateEffect,
	AddTrackToState: (self: AgentClass, State: string, Track: AnimationTrack, DisableTime: number) -> (),
	GetEffect: (self: AgentClass, Name: string) -> StateEffect,

	GetAnimator: (self: AgentClass) -> AnimatorController,

	--[[
		Change the state of the agent to the specified one, this limits/allows specific methods
		@param State The state to switch to, i. e. "Attacking", "Idle", "Stun";
		@param Time The time to remain in that state
	]]
	SwitchState: (self: AgentClass, State: State, Time: number) -> (),

	TakeDamage: (self: AgentClass, Amount: number) -> (),
	Heal: (self: AgentClass, Amount: number) -> (),

	AddTag: (self: AgentClass, Tag: string, Time: number) -> (),
	HasTag: (self: AgentClass, Tag: string) -> (boolean),
	RemoveTag: (self: AgentClass, Tag: string) -> (),

	__Character: CharacterClass,
	__Status: AgentStatusClass
}

export type AgentStatusEffect = {}

export type AgentStatusClass = {
	GetStat: (self: AgentStatusClass, Name: Stat) -> (number),
	Update: (self: AgentStatusClass, delta: number) -> (),


	Damage: (self: AgentStatusClass, Amount: number) -> (),
	Heal: (self: AgentStatusClass, Amount: number) -> (),
	GetHealth: (self: AgentStatusClass) -> (number, number),
	GetEnergy: (self: AgentStatusClass) -> (number),

	SetEnergy: (self: AgentStatusClass, Energy: number) -> (),
	UseEnergy: (self: AgentStatusClass, EnergyUsed: number) -> (),
	GiveEnergy: (self: AgentStatusClass, EnergyGiven: number) -> (),

	AddEffect: (self: AgentStatusClass, AgentStatusEffect) -> (),
	GetEffect: (self: AgentStatusClass, AgentStatusEffect) -> (),

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
export type Stat = 'Max_Health' | 'Max_Daze' | 'Health' | 'Attack' | 'Defense' | 'Critical_Rate' | 'Critical_Damage' | 'Penetration' | 'Pen_Ratio' | 'Daze' | 'Energy_Regeneration' | 'Affliction_Aptitude' | 'Affliction_Facility'
export type Element = 'Physical' | 'Energy' | 'Fire' | 'Ice' | 'Electric' | 'Wind' | 'Rock' | 'None'
export type CharacterStats = {[Stat]: number, Jog_Speed: number, Sprint_Speed: number, Walk_Speed: number}

export type EnemyStats = {
	[Stat]: number, 
	Weakness: {[number]: Element}, 
	Strength: {[number]: Element}, 
	Movement_Speed: number
}

export type CharacterData = {
	Display_Name: string,
	Nickname: string,
	Element: Element,
	Role: Role,
	Tier: Tier,
	Faction: string,
	NotOnBanner: boolean?,

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

	AddLinearMovement: (self: ServerCharacterClass, Direction: Vector3, Time: number) -> (),
}

export type ServerAgentClass = {
	Name: string,

	__Level: number,
	__User: number,
	__Main_Thread: thread,
	__Player_Assigned: Player,
	__Status: AgentStatusClass,
	__Active: boolean,
	__Character: ServerCharacterClass,

	GetId: (self: ServerAgentClass) -> (number),
	Init: (self: ServerAgentClass) -> (),
	Stop: (self: ServerAgentClass) -> (),
	Move: (self: ServerAgentClass) -> (),
	Rotate: (self: ServerAgentClass, Angle: number) -> (),

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
	SwitchState: (self: ServerAgentClass, State: string, Time: number) -> (),

	TakeDamage: (self: ServerAgentClass, Amount: number) -> (),
	Heal: (self: ServerAgentClass, Amount: number) -> (),
	GetHealth: (self: ServerAgentClass) -> (number, number),

	GiveEnergy: (self: ServerAgentClass, Energy: number) -> (),

	GetPivot: (self: ServerAgentClass) -> CFrame,
	PivotTo: (self: ServerAgentClass, Pivot: CFrame) -> (),

	AddTag: (self: ServerAgentClass, Tag: string, Time: number) -> (),
	HasTag: (self: ServerAgentClass, Tag: string) -> (boolean),
	RemoveTag: (self: ServerAgentClass, Tag: string) -> (),
}


--[[ CHARACTER CONTROLLERS ]]
export type AgentMovesetAbility = "Basic Attack" | "Special Attack" | "Chain Attack" | "Dodge" | "Dodge Counter" | "Quick Assist" | "Ultimate" | "Passive"

export type MovesetClass = {
	__Assigned: {[AgentMovesetAbility]: AbilityClass & ServerAbilityClass},
	
	--
	Assign: (self: MovesetClass, Key: string, Ability: AbilityClass) -> (),
	Verify: (self: MovesetClass, Agent: AgentClass, Type: string) -> boolean,
	
	Begin: (self: MovesetClass, Key: AgentMovesetAbility, Agent: AgentClass) -> (),
	
	GetInfoForSkill: (self: MovesetClass, Name: string) -> {},
	SetAbilityInformation: (self: MovesetClass, Data: {}) -> (),
}

export type Mults = "Daze_Mult" | "Damage_Mult" | "Affliction_Buildup"
export type AbilityDataKey = "Attack_State_Time" | "Speed" | "Animation_Speed" | "Attack_State_Time" | "Required_Energy" | Mults | string
export type AbilityInfo = {
	Base: {
		[AbilityDataKey | Mults | string]: number | {[number]: number},
	},

	Upgrades: {
		[Mults | string]: number | {[number]: number}
	}
}

export type SkillNames = "EX Special" | "Basic Attack" | "Special" | "Dodge" | "Quick Assist"
export type MovesetInfo = {
	["EX Special"]: AbilityInfo,
	["Basic Attack"]: AbilityInfo,
	["Special"]: AbilityInfo,
	["Dodge"]: AbilityInfo,
	["Quick Assist"]: AbilityInfo,
	["Dodge Counter"]: AbilityInfo,
	["Ultimate"]: AbilityInfo,
	["Chain Attack"]: AbilityInfo,
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
	__Cooldown: any,

	--[[
		Play an animation using any character controller, example:

		```lua
			local Path = "Characters.Goku.Abilities.Special.Default"
			Ability:PlayAnimation(CasterAgent, Path, {Fade = 0.15, Speed = 1.125})
		```

		@param Agent The agent to play an animation for
		@param Track The path to the animation track, i.e "Characters.Goku.Abilities.M1.1"; Starts from the Assets.Animations directory
		@param Data The properties of the track, FadeIn, Speed and Weight (all numbers, by default: 0, 1, 1)
	]]
	PlayAnimation: (self: AbilityClass, Agent: AgentClass, Track: string, Data: {
		Fade: number?,
		Speed: number?,
		Weight: number?,
		Active_Time: number?,
	}) -> (),
	CreateHitbox: (self: AbilityClass, Agent: AgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: EnemyClass) -> ()) -> (),

	Save: (self: AbilityClass, Agent: AgentClass, Key: string, Value: any) -> (),
	Get: (self: AbilityClass, Agent: AgentClass, Key: string) -> any,
	Increase: (self: AbilityClass, Agent: AgentClass, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	Play: (self: AbilityClass, Agent: AgentClass, Type: string, State: 'Begin' | 'End', Other: {any}) -> (),
	Begin: (self: AbilityClass, Agent: AgentClass, SequenceFrames: SequenceFrames) -> (),

	--[[
		Gets a value from the ability data
		@param Key The key to get from the ability data

		@return The value of the given key, can also be nil
	]]
	FromData: (self: AbilityClass, Key: AbilityDataKey) -> (any),
	SetData: (self: AbilityClass, Data: {}) -> (),
}

export type ServerAbilityClass = {
	__Cache: {},
	__Signal: RBXScriptSignal,
	__Hit: Signal<{
		Enemy: ServerEnemyClass,
		Agent: ServerAgentClass,
		Type: Element,
		Damage: number,
		Burst: boolean,
	}>,

	CreateHitbox: (self: ServerAbilityClass, Agent: ServerAgentClass, Offset: Vector3, Size: Vector3, Event: (Enemy: ServerEnemyClass) -> ()) -> (),

	Save: (self: ServerAbilityClass, Agent: ServerAgentClass, Key: string, Value: any) -> (),
	Get: (self: ServerAbilityClass, Agent: ServerAgentClass, Key: string) -> any,
	Increase: (self: ServerAbilityClass, Agent: ServerAgentClass, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	Play: (self: ServerAbilityClass, Agent: ServerAgentClass, Type: string, State: 'Begin' | 'End', Other: {any}) -> (),
	Begin: (self: ServerAbilityClass, Agent: ServerAgentClass, SequenceFrames: SequenceFrames) -> (),
	
	Hit: (self: ServerAbilityClass, Agent: ServerAgentClass, Enemy: ServerEnemyClass, Hit: HitEnemyData) -> (number),
	
	FromData: (self: ServerAbilityClass, Key: AbilityDataKey) -> (any),
	SetData: (self: ServerAbilityClass, Data: {}) -> (),
}

export type EnemyClass = {
	Name: string,
	__Status: EnemyStatus,
	__Appearance: AppearanceController,

	__Health: Fusion.Value<number>,
	__Daze: Fusion.Value<number>,
	__Affliction: Fusion.Value<number>,
	__Affliction_Type: Fusion.Value<string>,

	Init: (self: EnemyClass, Key: number) -> (),
	Move: (self: EnemyClass, Direction: Vector3) -> (),
	GetId: (self: EnemyClass) -> (number),

	PivotTo: (self: EnemyClass, At: CFrame) -> (),

	Hit: (self: EnemyClass) -> (),
	GetStat: (self: EnemyClass, Stat: Stat) -> (number),
	GetModel: (self: EnemyClass) -> Model,
	GetState: (self: EnemyClass) -> State,
	GetPivot: (self: EnemyClass) -> CFrame,
	GetHitbox: (self: EnemyClass) -> BasePart,
	IsMoving: (self: EnemyClass) -> EnemyClass,
	Rotate: (self: EnemyClass, Direction: Vector3) -> (),

	SwitchState: (self: EnemyClass, State: string, Time: number) -> (),
}

export type ServerEnemyClass = {
	Died: Signal<>,

	--
	__Name: string,
	__Status: EnemyStatus,
	__EnemyId: number,

	GetId: (self: ServerEnemyClass) -> (number),
	Init: (self: ServerEnemyClass, Key: number) -> (),
	Move: (self: ServerEnemyClass, Direction: Vector3) -> (),
	Stun: (self: ServerEnemyClass, Time: number) -> (),

	GetState: (self: ServerEnemyClass) -> State,
	GetPivot: (self: ServerEnemyClass) -> CFrame,
	GetHitbox: (self: ServerEnemyClass) -> BasePart,
	GetTarget: (self: ServerEnemyClass) -> ServerAgentClass,
	TimeSinceLastPivot: (self: ServerEnemyClass) -> number,
	Knockback: (self: ServerEnemyClass, Direction: Vector3, Power: number, Time: number) -> (),
	EnterDazedState: (self: ServerEnemyClass) -> (),

	TakeDaze: (self: ServerEnemyClass, Amount: number) -> (),
	TakeDamage: (self: ServerEnemyClass, Amount: number) -> (),
	TakeAffliction: (self: ServerEnemyClass, Affliction: Element, Amount: number) -> (),

	GetAfflictionStackedDamage: (self: ServerEnemyClass, Affliction: Element) -> (number),
	ResetAffliction: (self: ServerEnemyClass, Affliction: Element) -> (),
	GetAffliction: (self: ServerEnemyClass, Affliction: Element) -> (number),

	Rotate: (self: ServerEnemyClass, Direction: Vector3) -> (),
	PivotTo: (self: ServerEnemyClass, At: CFrame) -> (),

	Destroy: (self: ServerEnemyClass) -> ();

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

	GetStat: (self: EnemyStatus, Stat: Stat) -> (number),
	GetDamageTakenMultiplier: (self: EnemyStatus) -> (number),
	GetResistanceMultiplier: (self: EnemyStatus) -> (number),
	GetElementResistances: (self: EnemyStatus, Element: Element) -> (number, number),
	GetDazeMultiplier: (self: EnemyStatus) -> (number),

	FillAffliction: (self: EnemyStatus, Type: Element, Amount: number, Damage: number?) -> (),
	ResetAffliction: (self: EnemyStatus, Type: Element) -> (),
	GetAffliction: (self: EnemyStatus, Type: Element) -> (number),
	GetAfflictionStackedDamage: (self: EnemyStatus, Type: Element) -> (number),
	EnterDazedState: (self: EnemyStatus, fn: (DazeValue: number) -> ()) -> (),
}

export type HitEnemyData = {
	Damage: number,
	Stun: number,
	Daze: number,
	Affliction: Element,
	Attack_Type: AgentMovesetAbility,
	Affliction_Buildup: number?,
	DontChargeEnergy: boolean,

	Knockback: {number | number | number}?,
}

export type AbilityHitRequest = HitEnemyData & {

}

export type List<T> = {[number]: T}

export type UIComponent = {
	__Name: string,
	__Group: string,
	__Scope: Fusion.Scope,
	__Main_Frame: CanvasGroup | Frame,
	__Bound_To_Key: Enum.KeyCode,

	GetScope: (self: UIComponent) -> (Fusion.Scope & {Value: Fusion.Value<any, any>, Observer: Fusion.Observer}),
	GetFrame: (self: UIComponent) -> CanvasGroup | Frame,
	Peek: (self: UIComponent, Value: Fusion.Value<any, any>) -> (any),
	CheckAvailable: (self: UIComponent) -> (boolean),

	Init: (self: UIComponent) -> (),
	Link: (self: UIComponent) -> (Instance?),
	Bind: (self: UIComponent) -> (),
	Set: (self: UIComponent, State: boolean?) -> (),
	BindToStateChange: (self: UIComponent, Callback: (State: boolean) -> ()) -> (),

	[string]: (self: UIComponent) -> (any),
}

export type UIGetSetButton = {
	GetButton: (self: UIComponent, Name: string) -> {Button: TextButton, UIScale: UIScale},
	SetButton: (self: UIComponent, Name: string, State: boolean) -> ()
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


export type PlayerArtifactData = {
	Id: string,
	Name: string,
	Level: number,
	Tier: string,
	Slot: number,

	Stats: {
		Main_Stat: MainStat,
		Sub_Stats: Substats,
	},

	Equipped: string?,
}

export type PlayerArtifactDataClass = {
	__Id: string,
	__Tier: string,
	__Name: string,
	__Level: number,
	__Slot: number,
	__Equipped: string?,

	__Stats: {
		Main_Stat: MainStat,
		Sub_Stats: Substats,
	},

	GetMainStat: (self: PlayerArtifactDataClass) -> (string, number),
	Compress: (self: PlayerArtifactDataClass) -> ({string | buffer}),
	ToData: (self: PlayerArtifactDataClass) -> (PlayerArtifactData),
}

export type Weapon_Data = {
	Name: string,
	Role_Needed: Role,
	Tier: Tier,

	ModelName: string,
	Passive_Description: string,

	Main_Stat: {
		StatName: Stat,
		Base: number,
		UpgradePerAscension: number,
	},

	Sub_Stat: {
		StatName: Stat,
		Base: number,
		UpgradePerAscension: number,
	},
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
export type AgentArtifactClass = {
	Name: string,
	Slot: number,
	Level: number,

	--
	Main_Stat: MainStat,
	Sub_Stats: Substats,

	-- #Privates
	__Cache: {},
	__Events: {},
	__Count: number,

	--
	Extend: (self: AgentArtifactClass, Slot: number, Level: number, MainStat: MainStat, SubStat: Substats) -> AgentArtifactClass,

	GetPieceCount: (self: AgentArtifactClass) -> (number),

	OnEffectProcess: (self: AgentArtifactClass, Event: (Effect: Element, Data: Process_Event_Data) -> ()) -> (),
	OnHitProcess: (self: AgentArtifactClass, State: Hit_Process_State, Event: (Data: Process_Event_Data) -> (number, number)) -> (),
}

export type AnimationDataOptions =  {Name: string?, Fade: number?, Speed: number?, Weight: number?, Priority: Enum.AnimationPriority?, Active_Time: number?}
export type EffectAnyData = {[string]: (Instance | any)}
export type GamePlace = "Lobby" | "Mission" | "AFK" | "Raid"


export type ArtifactDataClass = {
	Name: string,
	Slot: number,
	Level: number,

	Main_Stat: MainStat,
	Substats: Substats,
}
export type WeaponDataClass = {
	Name: string,
	Level: number,
}
export type AgentDataClass = {
	Name: string,
	Level: number,

	Items: {
		Weapon: WeaponDataClass,
		Artifacts: {ArtifactDataClass},
	},

	Skin: string,
}

export type ClientAgentData = {
	Name: string,
	Level: number,
	Experience: number,
	Weapon: {
		Level: number,
		Name: string,
	},

	Artifacts: {
		
	},
}

export type PartyPlayerTeam = {[number]: AgentDataClass}
export type PartyState = typeof(_GameEnum.PartyStates.Idle)
export type PartyPlayer = {
	PlayerObject: Player,
	Level: number,

	-- The player associated ID, commonly just the UserID
	GetId: (self: PartyPlayer) -> (number),
}

export type PartyClass = {
	Code: number,
	__Players: {[number]: PartyPlayer},

	__Stage: string,
	__FriendsOnly: boolean,
	__State: PartyState,
	__Owner: number,
	__State_Name: string,
	__Max_Players: number,
	__Teams: {},

	--
	AddPlayer: (self: PartyClass, Player: PartyPlayer) -> (),
	HasPlayer: (self: PartyClass, Id: number) -> (),
	RemovePlayer: (self: PartyClass, Player: PartyPlayer) -> (),

	GetStateName: (self: PartyClass) -> string,
	GetStage: (self: PartyClass) -> string,
	GetStagePlace: (self: PartyClass) -> (),
	GetState: (self: PartyClass) -> PartyState,
	GetPlayers: (self: PartyClass) -> {PartyPlayer},
	GetRawPlayers: (self: PartyClass) -> ({Player}),
	GetMaxPlayers: (self: PartyClass) -> (number),

	GetPlayerTeam: (self: PartyClass, Player: PartyPlayer) -> (),
	SetPlayerTeam: (self: PartyClass, Player: PartyPlayer, Team: PartyPlayerTeam?) -> (),
	GetSimplifiedTeam: (self: PartyClass, Player: PartyPlayer) -> (),
	GetPlayerCompressedTeam: (self: PartyClass, Player: PartyPlayer) -> (),

	SetState: (self: PartyClass, State: number) -> (),
	SetStage: (self: PartyClass, Stage: string) -> (),

	--[[
		Compress the table in order to be sent via network

		@return `table`: compressed party data
	]]
	Compress: (self: PartyClass, Ignore: PartyPlayer) -> (),

	Destroy: (self: PartyClass) -> (),
}

export type MainStat = {[Stat]: number}
export type PlayerAgentData = {
	Name: string,
	Level: number,

	Obtained: number,
	Skins: {},

	Weapon: WeaponDataClass,

	Artifacts: {
		[number]: ArtifactDataClass,
	}
}

export type PlayerProfileData = {
	Level: number,
    Experience: number,

    Stats: {
        TotalDamage: number,
        TotalDaze: number,
        TotalKills: number,
        TotalPulls: number,
        TotalGemsSpent: number,
        TotalCurrencySpent: number,
    },

    Agents: {
		[number]: PlayerAgentData,
	},
    Achievements: {},
    Titles: {},
    Items: {
		Artifacts: {},
		Progress: {},
		Event: {},
	},
    Warnings: {},
}

export type Signal<T...> = RBXScriptSignal & {Fire: (self: RBXScriptSignal, T...) -> ()}
export type ClientAreaClass = {
	--
	__Params: OverlapParams,
	__IsInside: boolean,
	__AreaInstances: {Instance} | Instance,
	__Loop: RBXScriptConnection,

	--
	OnEnter: Signal<>,
	OnLeave: Signal<>,


	Destroy: (self: ClientAreaClass) -> (),

	__IsPartInPlayer: (self: ClientAreaClass, Part: BasePart) -> (boolean),
	__GetPartsInInstances: (self: ClientAreaClass) -> (boolean),
}

export type PlayerAgentDataClass = {
	Name: string,
	Level: number,
	Experience: number,

	ObtainmentDate: number,
	Skins: {},

	Weapon: WeaponDataClass,

	Artifacts: {
		[number]: ArtifactDataClass,
	},

	SetWeapon: (self: PlayerAgentDataClass, WeaponName: string, Level: number) -> (),
	SetArtifacts: (self: PlayerAgentDataClass, Artifacts: {ArtifactDataClass}) -> (),
	ToData: (self: PlayerAgentDataClass) -> (PlayerAgentData),
	Compress: (self: PlayerAgentDataClass) -> ({}),
}

export type Fusion = Fusion.Fusion
export type ButtonContainer<A, B, C, D, E, F, G, H> = {
	[A | B? | C? | D? | E? | F? | G? | H?]: TextButton,
}


export type Stage_Objective = "KillEnemies" | "TimeSurvive" | "PushLoad" | "ReachPlace" | "TalkTo" | "AllReachPlace"
export type Reward_Type = "Artifact" | "Gold" | "Gems" | "Agent"
export type Goal = {
	[Stage_Objective]: number,
}
export type EventHandlerState = {Dead: boolean, [string | Stage_Objective]: any}
export type Action = "KickPlayer"
export type Stage_Key_Event = {
	Actions: {
		[Action]: string,
	},
	Objective: string,
	Goal: Goal,

	Active_Triggers: {string},

	Finished: (State: EventHandlerState) -> (string),

	-- Teleport all players to an area.
	Global: boolean?,

	-- Only used if Global is turned on
	EventPlace: string?,

	Enemies: {
		[number]: {string | number},
	},
	TimeLimit: number?,
}

--[[

## Stage Key Event
Events that happen in that stage, the first one is loaded and then the next one is changed to after the first one finishes, etc

### Objective description tags:
- {objective[n]} where `n` is the type of objective, returns the value of the objective
- {player} refers to the name of the player
- {time} updates the time as it changes

### Finished:
- Handler, which is passed a `Goal` type for the state at which the event was finished, be it completed or time limit, or death, etc.
- Handler returns a string that indicates the next stage

]]
export type Rating = "X" | "B" | "A" | "S" | "SSS"
export type Stage_Act = {
	Requisites: {

	},

	Rewards: {
		Handler: (Objectives: {[string]: boolean}) -> (Rating),

		[Reward_Type]: string | number,
	},

	Guide: {
		Begin: Stage_Key_Event,
		[string]: Stage_Key_Event,
	}
}

export type Stage = {
	Name: string,
	Map: string,

	Acts: {
		[string]: Stage_Act,
	},
}

export type MissionClass = {
	Finished: Signal<>,

	__Active: boolean,
	__Act: string,
	__Stage: string,
	__Is_Finished: boolean,
	__Current_Active_Triggers: {RBXScriptConnection},
	__Current_Events: {[string]: EventClass},

	--
	Begin: (self: MissionClass) -> (),

	--[[
		Begin the event associated to the current mission
		@param Event : `string` the event to be started, passing none will result in it loading the "Begin" event
	]]
	BeginEvent: (self: MissionClass, Event: ("Begin" | string)?, Players: {StagePlayer}) -> (),
	SummonEnemyWave: (self: MissionClass, Wave: number) -> (),

	--[[
		Sync with all clients the current events and information
	]]
	Sync: (self: MissionClass, Players: {StagePlayer}, Type: number, ...any) -> (),

	--[[
		Sets up the area triggers for each event, only in the scenario where there are any area triggers
	]]
	DetectAreaTriggers: (self: MissionClass) -> (),
	CleanUpTriggers: (self: MissionClass) -> (),

	IsFinished: (self: MissionClass) -> (boolean),
}

export type EventClass = {
	Finished: Signal<string>,

	__Players: {StagePlayer},
	__Finish_Status: boolean,
	__Event: string,
	__Stage: string,
	__Act: string,
	__Current_Time: number,
	__Current_Wave_Thread: thread?,
	__Current_Wave_Connection: RBXScriptConnection?,
	__Current_Goals: Goal,
	__Current_State: {[Stage_Objective]: (number | boolean)?, Dead: boolean},

	AddPlayer: (self: EventClass, Player: StagePlayer) -> (),

	Start: (self: EventClass) -> (),
	SummonEnemyWave: (self: EventClass, Wave: number) -> (),
	Destroy: (self: EventClass) -> (),

	HasGoal: (self: EventClass, Type: Stage_Objective) -> (boolean),
	IsFinished: (self: EventClass) -> (),

	--[[
		Update the progress in teh current mission
		@param Type : `Goal` the goal type to be updated
		@param Value : `any` the value of the new goal, incremental in case of numbers.
	]]
	UpdateProgress: (self: EventClass, Type: Stage_Objective, Value: any) -> (),

	GetCorrectedState: (self: EventClass) -> (),
}

export type StagePlayer = {
	__Player_Object: Player,
	__Designated_Id: number,
	__Team: {ServerAgentClass},

	GetId: (self: StagePlayer) -> number,
	GetTeam: (self: StagePlayer) -> {ServerAgentClass},
	GetBase: (self: StagePlayer) -> Player,
}

export type CutsceneClass = {
	Completed: Signal<>,

	__Cache: {any},
	__Active: boolean,
	__Name: string,
	__Time: number,
	__Thread: thread?,

	--
	Sequence: (self: CutsceneClass, Data: {any}) -> (),
	Play: (self: CutsceneClass, Data: {any}) -> (),
	CleanUp: (self: CutsceneClass) -> (),
	MoveCamera: (self: CutsceneClass, To: CFrame, Info: {number | string}?) -> (Tween?),

	SetFOV: (self: CutsceneClass, FOV: number, Info: {number | string}?) -> (Tween?),

	--[[
		Wait the given amount of seconds
		@yields
	]]
	Wait: (self: CutsceneClass, Time: number) -> (),

	--[[
		Will be cleaned up after the cutscene ends
		@param Item : `any`
	]]
	Add: (self: CutsceneClass, Item: any) -> (),

	--[[
		Remove an item from the clean up queue in case it must persist
		@param Item : `any`
	]]
	Remove: (self: CutsceneClass, Item: any) -> (),

	--[[
		Finish the cutscene, clean up and then call the `.Completed` event
	]]
	End: (self: CutsceneClass) -> ()
}

return {
	NOT_IMPLEMENTED_ERROR = function()
		warn("Method", debug.info(2, "n"), "not implemented. Consider writing a hardcoded value of return")
	end
};