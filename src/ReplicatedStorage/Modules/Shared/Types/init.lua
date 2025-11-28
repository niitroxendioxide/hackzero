local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyMovement = require(ReplicatedStorage.Modules.Shared.Classes.Enemy.EnemyMovement)
--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Fusion = require(ReplicatedStorage.Modules.Client.Libraries.Fusion)
local _GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)

-- [[ Other ]]

--// B rank, A rank, S rank
export type Tier = 'Epic' | 'Legendary' | 'Mythical' | 'Common'

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
	__Current_Height_Thread: thread?,
	__Current_Height_Tween: Tween?,
	__Extra_Height: number,
	__Root_Attachment: Attachment,
	__Target_Attachment: Attachment,
	__Bound_Objects: {[Instance]: (self: Instance, State: boolean, ExtraState: number) -> ()},

	--[[
		@param ExtraState is always 1. Useful to identify whether the caller is the appearance controller or not.
	]]
	BindObject: (self: AppearanceController, Object: Instance, Toggle: (self: Instance, State: boolean, ExtraState: number) -> ()) -> (),
	UnbindObject: (self: AppearanceController, Object: Instance) -> (),

	Raise: (self: AppearanceController, Factor: number, Time: number, Instant: boolean?) -> (),
	Land: (self: AppearanceController) -> (),
	GetAddedHeight: (self: AppearanceController) -> (number),

	GetModel: (self: AppearanceController) -> (Model),

	BindParticles: (self: AppearanceController, ParticleHolder: Instance) -> (),
	UnbindParticles: (self: AppearanceController, ParticleHolder: Instance) -> (),
	SetVisible: (self: AppearanceController, State: boolean) -> (),
	JoinTo: (self: AppearanceController, BasePart: BasePart) -> (),

	EditPartValue: (self: AppearanceController, Part: BasePart, Value: number) -> (),
	Destroy: (self: AppearanceController) -> (),
}

export type AnimatorController = {
	__Character: CharacterClass,
	__Tracks: {[string]: AnimationTrack},
	__Directory: string,
	__Movement_Tracks: {},
	__IsMoving: boolean,

	Init: (self: AnimatorController) -> (),
	Play: (self: AnimatorController, Track: string) -> (),
	GetTrack: (self: AnimatorController, Track: string) -> AnimationTrack,
	AddModelMovingAnimation: (self: AnimatorController, Track: AnimationTrack, Weight: number) -> (),
	RemoveTrackFromMovement: (self: AnimatorController, Track: AnimationTrack) -> (),
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
	__Forward_Velocities: {},
	__Added_Colliders: {[{BasePart}]: boolean?},

	__Collider: BasePart,


	Run: (self: PhysicsController) -> (),
	Pause: (self: PhysicsController) -> (),

	CreateCollider: (self: PhysicsController) -> (),
	GetCollider: (self: PhysicsController) -> BasePart,
	SetColliderGroupState: (self: PhysicsController, Group: {}, State: boolean?) -> (),

	PivotTo: (self: PhysicsController, PivotCFrame: CFrame) -> (),
	GetPivot: (self: PhysicsController) -> CFrame,

	Rotate: (self: PhysicsController, Direction: Vector3) -> (),
	SetMovementVelocity: (self: PhysicsController, Velocity: Vector3) -> (),
	StopMovement: (self: PhysicsController) -> (),
	ApplyImpulse: (self: PhysicsController, Velocity: Vector3) -> (),
	ApplyForwardImpulse: (self: PhysicsController, Power: number, FadeOutTime: number) -> (),
	RemoveForwardImpulse:  (self: PhysicsController, Object: {}) -> (),
	Update: (self: PhysicsController, Delta: number) -> (),
}

export type CharacterClass = {
	Name: string,

	__Controller: PhysicsController,
	__Appearance: AppearanceController,
	__Animator: AnimatorController,
	__States: StatesClass,
	__Physics_Enabled: boolean,

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
	SetPhysicsEnabled: (self: CharacterClass, State: boolean) -> (),

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

export type State = 'Idle' | 'Attacking' | 'Dashing' | 'Stunned' | 'Frozen' | 'Airborne'
export type StatesClass = {
	__Effects: {},
	__Character: string,
	__Keys: {Running: boolean, Sprinting: boolean},
	__State: State,
	__Last_Change: number,

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

	GetPivot: (self: GenericClass) -> CFrame,

	BlockRotation: (self: GenericClass, Time: number) -> (),
	GetId: (self: GenericClass) -> (number),
	GetEnergy: (self: GenericClass) -> (number),

	AddTag: (self: GenericClass, Tag: string, Time: number) -> (),
	RemoveTag: (self: GenericClass, Tag: string) -> (),
	HasTag: (self: GenericClass, Tag: string) -> (boolean),

	GetModel: (self: GenericClass) -> Model,
	GetUltBar: (self: GenericClass) -> number,
	GetSkillLevel: (self: GenericClass, Name: string) -> (number),

	Walk: (self: GenericClass, Time: number) -> (),
	SwitchState: (self: GenericClass, State: State, Time: number) -> (),

	GetEffect: (self: GenericClass, ...any) -> (),

	--
	GetAnimator: (self: GenericClass) -> AnimatorController,
	ApplyImpulse: (self: GenericClass, Impulse: Vector3) -> (),

	GetUltimate: (self: GenericClass) -> (number),

	GiveEnergy: (self: GenericClass) -> (number),
	UseEnergy: (self: GenericClass, Amount: number) -> (),

	--
	TakeDamage: (self: GenericClass, Amount: number) -> (),
}
-- [[ INPUTS ]]
export type KeybindData = {
	Release: boolean?,

	Callback: (any) -> () | any?,
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
export type Stat = 'Daze_Resistance' | 'Speed' | 'Max_Health' | 'Max_Daze' | 'Health' | 'Attack' | 'Defense'
| 'Critical_Rate' | 'Critical_Damage' | 'Penetration' | 'Pen_Ratio' | 'Daze' | 'Energy_Regeneration' | 'Affliction_Aptitude' | 'Affliction_Facility'
| 'Stun%' | 'LA_Blunt%' | 'LA_Slash%' | 'Blunt%' | 'Slash%'
export type Element = 'Physical' | 'Energy' | 'Fire' | 'Ice' | 'Electric' | 'Wind' | 'Rock' | 'None' | 'Water'
export type CharacterStats = {[Stat]: number, Jog_Speed: number, Sprint_Speed: number, Walk_Speed: number}

export type EnemyStats = {
	[Stat]: number,
	Weakness: {[number]: Element},
	Strength: {[number]: Element},
	Movement_Speed: number
}

export type AscensionData = {
	Description: number,

	Passive_Buffs: {
		Stage: 'BeforeDamage' | 'AfterDamage' | '',
	},
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
	Moveset_Data: MovesetInfo,
	Ascension_Data: {
		[number]: AscensionData,
	},
}

export type CharacterAppearanceData = {
	Height: number,
}

export type Mults = "Daze_Mult" | "Damage_Mult" | "Affliction_Buildup"
export type AgentMovesetAbility = "Basic Attack" | "Special Attack" | "Chain Attack" | "Dodge" | "Dodge Counter" | "Quick Assist" | "Ultimate" | "Passive"

export type AbilityDataKey = "Attack_State_Time" | "Speed" | "Animation_Speed" | "Attack_State_Time" | "Required_Energy" | "Attack_Data" | Mults | string
export type AbilityInfo = {
	Upgrade_Requirements: {
		[string]: number,
	}?,
	Description: string?,

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
	["Passive"]: {
		Meters: {
			[string]: {
				Max: number,
				Id: number,
				EmptySpeed: number?,
			}
		}
	}
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

	SetWorldSpeed: (self: ServerEnemyClass, Speed: number, Time: number) -> (),
	SwitchState: (self: EnemyClass, State: string, Time: number) -> (),
}

export type EnemyMovementClass = {
	__World_Speed: number,
	SetWorldSpeed: (self: EnemyMovementClass, number, number?) -> (),
	Move: (self: EnemyMovementClass, Direction: vector | Vector3) -> (),
}

export type ServerEnemyClass = {
	Died: Signal<>,

	--
	__Name: string,
	__Status: EnemyStatus,
	__EnemyId: number,
	__Movement: EnemyMovementClass,
	__Next: number,
	__LastMovement: number,
	__Current_Target: any,

	SetWorldSpeed: (self: ServerEnemyClass, Speed: number, Time: number) -> (),

	GetId: (self: ServerEnemyClass) -> (number),
	Init: (self: ServerEnemyClass, Key: number) -> (),
	Move: (self: ServerEnemyClass, Direction: Vector3 | vector) -> (),
	Stun: (self: ServerEnemyClass, Time: number, is_airborne: boolean?) -> (),

	GetState: (self: ServerEnemyClass) -> State,
	GetPivot: (self: ServerEnemyClass) -> CFrame,
	GetHitbox: (self: ServerEnemyClass) -> BasePart,
	GetTarget: (self: ServerEnemyClass) -> GenericClass,
	TimeSinceLastPivot: (self: ServerEnemyClass) -> number,
	Knockback: (self: ServerEnemyClass, Direction: Vector3, Power: number, Time: number) -> (),
	EnterDazedState: (self: ServerEnemyClass) -> (),

	TakeDaze: (self: ServerEnemyClass, Amount: number) -> (boolean),

	--[[
		@return Died
	]]
	TakeDamage: (self: ServerEnemyClass, Amount: number) -> (boolean),
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
	IsAirborne: (self: EnemyStatus) -> (boolean),
	SwitchState: (self: EnemyStatus, State: State) -> (),

	GetStat: (self: EnemyStatus, Stat: Stat) -> (number),
	GetDamageTakenMultiplier: (self: EnemyStatus) -> (number),
	GetResistanceMultiplier: (self: EnemyStatus) -> (number),
	GetElementResistances: (self: EnemyStatus, Element: Element) -> (number, number),
	GetDazeMultiplier: (self: EnemyStatus) -> (number),
	GetElementMultiplier: (self: EnemyStatus, Element: Element) -> (number),

	FillAffliction: (self: EnemyStatus, Type: Element, Amount: number, Damage: number?) -> (),
	ResetAffliction: (self: EnemyStatus, Type: Element) -> (),
	GetAffliction: (self: EnemyStatus, Type: Element) -> (number),
	GetAfflictionStackedDamage: (self: EnemyStatus, Type: Element) -> (number),
	EnterDazedState: (self: EnemyStatus, fn: (DazeValue: number) -> ()) -> (),
}

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

	--[[
		Link the component to an existing UI/ScreenGUI; whatever preference you have.
	]]
	Link: (self: UIComponent) -> (Instance?),
	Bind: (self: UIComponent) -> (),

	--[[
		Sets the state of the component
		@param State Whether its active or not
		@param Raw Call the method ignoring the callback or not
	]]
	Set: (self: UIComponent, State: boolean?, Raw: boolean?) -> (),
	BindToStateChange: (self: UIComponent, Callback: (State: boolean) -> ()) -> (),

	[string]: (self: UIComponent, ...any) -> () | any?,
}

export type UIGetSetButton = {
	GetButton: (self: UIComponent, Name: string) -> {Button: TextButton, UIScale: UIScale},
	SetButton: (self: UIComponent, Name: string, State: boolean) -> ()
}

export type Artifact_Substat = "Health%" | "Health" | "Attack" | "Attack%" | "Defense" | "Defense%" | "Crit_Rate" | "Crit_Damage" | "Penetration" | "Affliction_Aptitude"

export type Artifact_Data = {
	Name: string,
	Tier: Tier,
	Icon: number,

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
	Tier: number | string,
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
	__Equipped: PlayerAgentDataClass?,

	__Stats: {
		Main_Stat: MainStat,
		Sub_Stats: Substats,
	},

	GetMainStat: (self: PlayerArtifactDataClass) -> (string, number),
	Compress: (self: PlayerArtifactDataClass) -> ({string | buffer}),
	ToData: (self: PlayerArtifactDataClass) -> (PlayerArtifactData),

	IsEquipped: (self: PlayerArtifactDataClass) -> (boolean),
	EquipTo: (self: PlayerArtifactDataClass, Agent: PlayerAgentDataClass?) -> (PlayerAgentDataClass?, string?),
}

export type Drive_Data = {
	Name: string,
	Role_Needed: Role,
	Tier: Tier,

	IconId: number,
	ModelName: string,
	Passive_Description: string,

	Main_Stat: {
		StatName: Stat,
		Base: number,
		UpgradePerLevel: number,
	},

	Advanced_Stat: {
		StatName: Stat,
		Base: number,
		UpgradePerAscension: number,
	},
}

export type Substats = {
	[Artifact_Substat]: number,
}

export type AnimationDataOptions =  {Name: string?, Fade: number?, Speed: number?, Weight: number?, Priority: Enum.AnimationPriority?, Active_Time: number?, Model: Model?}
export type EffectAnyData = {[string]: (Instance | any)}
export type GamePlace = "Lobby" | "Mission" | "AFK" | "Raid"


export type ClientAgentData = {
	Name: string,
	Level: number,
	Experience: number,
	Drive: string,
	Ascensions: number,

	Skills: {
		Basic_Attack: number,
		Ultimate: number,
		Special: number,
	},

	Artifacts: {
		[number]: string,
	},
}

export type PartyPlayerTeam = {[number]: PlayerAgentData}
export type PartyState = typeof(_GameEnum.PartyStates.Idle)
export type PartyPlayer = {
	UserId: number,
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
	__Ready: {PartyPlayer},
	__Player_Count: number,
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
	SwitchStage: (self: PartyClass, Type: string, Stage: string, Act: string) -> (),

	GetPlayerTeam: (self: PartyClass, Player: PartyPlayer) -> (PartyPlayerTeam),
	SetPlayerTeam: (self: PartyClass, Player: PartyPlayer, Team: PartyPlayerTeam?) -> (),
	GetSimplifiedTeam: (self: PartyClass, Player: PartyPlayer) -> (),
	GetPlayerCompressedTeam: (self: PartyClass, Player: PartyPlayer) -> (),

	SetState: (self: PartyClass, State: number) -> (),
	SetStage: (self: PartyClass, Stage: string) -> (),

	SetReady: (self: PartyClass, Player: PartyPlayer) -> (),

	--[[
		@return Boolean: Whether it did cancel or not.
	]]
	CancelReady: (self: PartyClass, Player: PartyPlayer) -> (boolean),
	IsReady: (self: PartyClass) -> (boolean),

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

	Drive: PlayerDriveData,
	Ascensions: number,
	Skills: {
		Basic_Attack: number,
		Ultimate: number,
		Special: number,
	},

	Artifacts: {
		[number]: string,
	}
}

export type SkinToken = {
	Name: string,
	Amount: number,
}

export type CharacterToken = {
	Name: string,
	Amount: number,
}

export type PlayerProfileData = {
	Level: number,
    Experience: number,

	Gems: number,
	Money: number,

    Stats: {
        TotalDamage: number,
        TotalDaze: number,
        TotalKills: number,
        TotalPulls: number,
        TotalGemsSpent: number,
        TotalCurrencySpent: number,
    },

	Settings: {
		Graphics: {},
		QOL: {},
		Sounds: {},
		Keybinds: {},
	},

	Quests: {
		Daily: {},
		Main: {},
		Interactions: {},
	},

	Companions: {},
    Agents: {
		[number]: PlayerAgentData,
	},
    Achievements: {},
    Titles: {},
    Items: {
		Drives: {PlayerDriveData},
		Artifacts: {PlayerArtifactData},
		Progress: {},
		Event: {},
		Skins: {},
		Tokens: {CharacterToken | SkinToken},
	},
    Warnings: {},
}

export type Signal<T...> = RBXScriptSignal & {Fire: (self: RBXScriptSignal, T...) -> (), Connect: (fn: (T...) -> ()) -> ()}
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
	Skills: {
		Basic_Attack: number,
		Ultimate: number,
		Special: number,
	},

	Ascensions: number,
	Drive: string,

	Artifacts: {
		[number]: string,
	},

	EquipArtifactToSlot: (self: PlayerAgentDataClass, SlotId: number, Artifact: PlayerArtifactDataClass?) -> (string?),
	SetDrive: (self: PlayerAgentDataClass, Drive: string?) -> (string?),
	SetArtifacts: (self: PlayerAgentDataClass, Artifacts: {string}) -> (),
	SetAscensions: (self: PlayerAgentDataClass, Amount: number) -> (),
	SetSkill: (self: PlayerAgentDataClass) -> (number),
	ToData: (self: PlayerAgentDataClass) -> (PlayerAgentData),
	Compress: (self: PlayerAgentDataClass) -> ({}),
}

export type Fusion = Fusion.Fusion
export type ButtonContainer<A, B, C, D, E, F, G, H> = {
	[A | B? | C? | D? | E? | F? | G? | H?]: TextButton,
}

export type CutsceneClass = {
	Completed: Signal<>,

	__Cache: {any},
	__Objects: {[string]: any},
	__Active: boolean,
	__Name: string,
	__Time: number,
	__Camera_User: Player?,
	__Thread: thread?,
	__Camera_Filter: (...any) -> boolean,

	--
	IsCameraUser: (self: CutsceneClass) -> (boolean),
	SetCameraUser: (self: CutsceneClass, Player: Player) -> (),
	Sequence: (self: CutsceneClass, ...any) -> (),
	Play: (self: CutsceneClass, ...any) -> (),
	CleanUp: (self: CutsceneClass) -> (),
	MoveCamera: (self: CutsceneClass, To: CFrame, Info: {number | string}?) -> (Tween?),

	SetFOV: (self: CutsceneClass, FOV: number, Info: {number | string}?) -> (Tween?),

	GetPlayerEnvironment: (self: CutsceneClass) -> {Model: Rig, CFrame: CFrame, AgentName: string},

	AnimateCamera: (self: CutsceneClass, At: CFrame, Animation: string) -> (AnimationTrack?),


	--[[
		Add a handler to filter the parameters used to determine whether the camera will be used or not in this cutscnee
		@param Handler
	]]
	FilterCameraUsage: (self: CutsceneClass, fn: (...any) -> boolean) -> (),

	--[[
		Given any parameters, the cutscene handler will automatically manage whether it will use the camera or not, so that the usage can be marked and free'd afterwards, without
		any worry of misusage of the cutscenes camera handler

		@param any
	]]
	WillUseCamera: (self: CutsceneClass, ...any) -> boolean,

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

--
export type PlayerDriveData = {
	Id: string,
	Name: string,

	Level: number,
	Trait: string?,
	Equipped: string?,
	Experience: number,
}

export type PlayerDriveDataClass = {
	__Id: string,
	__Name: string,

	__Level: number,
	__Experience: number,
	__Trait: number,
	__Equipped: PlayerAgentDataClass?,

	Compress: (self: PlayerDriveDataClass) -> ({string | buffer}),
	ToData: (self: PlayerDriveDataClass) -> (PlayerDriveData),

	EquipTo: (self: PlayerDriveDataClass, Agent: PlayerAgentDataClass) -> (string?, string?),
	IsEquipped: (self: PlayerDriveDataClass) -> (boolean),
}


--
return {
	NOT_IMPLEMENTED_ERROR = function()
		warn("Method", debug.info(2, "n"), "not implemented. Consider writing a hardcoded value of return")
	end
};