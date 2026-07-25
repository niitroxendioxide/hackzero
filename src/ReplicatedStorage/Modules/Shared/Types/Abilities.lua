local Default = require(script.Parent)
local Agents = require(script.Parent.Agents)

export type SequenceFrames = {{number | (self: Sequence, delta: number) -> ()}}
export type Sequence = {
	__cache: {[any]: any},
	__frames: SequenceFrames,
	__currentTime: number,

	--
	Start: (self: Sequence) -> Sequence,
	Pause: (self: Sequence) -> Sequence,
	Destroy: (self: Sequence) -> (),
	GetSpeed: (self: Sequence) -> (),

	--
	Update: (self: Sequence) -> (),
	After: (self: Sequence, fn: (self: Sequence) -> ()) -> Sequence,

	Add: (self: Sequence, Time: number, fn: (self: Sequence) -> ()) -> () 
	& (self: Sequence, Start_Time: number, End_Time: number, fn: (self: Sequence) -> ()) -> (),
}

export type HitboxAttackData = {Size: Vector3, Offset: Vector3, Hit_Function: (Target: any) -> ()}


export type Caster = (Agents.ServerAgentClass | Agents.AgentClass | Agents.Enemy | Agents.ClientEnemy) & {
	SwitchState: (self: Caster, State: Default.State, Time: number, Unaffected: boolean?) -> (),
}
export type Target = Caster
export type TargetFinderFunction = (Caster: Agents.AgentClass) -> (number, Agents.ClientEnemy)

export type ServerEnemy = Agents.Enemy
export type ClientEnemy = Agents.ClientEnemy
export type ServerAgent = Agents.ServerAgentClass
export type ClientAgent = Agents.AgentClass


export type ClientSkillContext = {IsSignal: boolean, Target: Target};

export type HitVFXData = {
	Emitter: string?, 
	Offset: CFrame?, 
	HueShift: number?, 
	HueShiftFilter: ((any) -> (number))?, HitstopTime: number?,
	Highlight: boolean?,
	HighlightColor: Color3,

	Audio: {
		Id: string, 
		Volume: number?, 
		Priority: string?,
	}?,
}

export type AbilityClass = {
	__Cache: {},
	__Hooks: {[number]: {(...any) -> ()}},
	__Signal: RBXScriptSignal,
	__Cooldown: any,
	__Name: string,
	__Target_Finder: TargetFinderFunction?,
	Name: string,

	ConnectHook: (self: AbilityClass, hook_type: number, fn: (...any) -> ()) -> (),

	--[[
		Play an animation using any character controller, example:

		```lua
			local Path = "Goku.Abilities.Special.Default" -- Starts from 'Characters' directory, by default.
			Ability:PlayAnimation(CasterAgent, Path, {Fade = 0.15, Speed = 1.125})
		```

		@param Agent The agent to play an animation for
		@param Track The path to the animation track, i.e "Characters.Goku.Abilities.M1.1"; Starts from the Assets.Animations directory
		@param Data The properties of the track, FadeIn, Speed and Weight (all numbers, by default: 0, 1, 1)
	]]
	PlayAnimation: (self: AbilityClass, Agent: Caster, Track: string, Data: {
		Fade: number?,
		Speed: number?,
		Weight: number?,
		Active_Time: number?,
	}) -> (),
	CreateHitbox: (self: AbilityClass, Agent: Caster, Offset: Vector3, Size: Vector3, Event: (Enemy: Agents.ClientEnemy) -> ()) -> (),
	SetTargetFinder: (self: AbilityClass, fn: TargetFinderFunction) -> (),

	Save: (self: AbilityClass, Agent: Caster, Key: string, Value: any) -> (),
	Get: <T>(self: AbilityClass, Agent: Caster, Key: string) -> T,
	Increase: (self: AbilityClass, Agent: Caster, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	Play: (self: AbilityClass, Agent: Caster, Type: string, State: 'Begin' | 'End', Context: ClientSkillContext) -> (),


	--[[
		Push a value to the connection buffer before stablishing the connection, this method is only usable with hooks prior to the skill connection
		@param Value the value to add to the context buffer
	]]
	PushToContextBuffer: (self: AbilityClass, value: any) -> (),

	--[[
		Useful to match the heights of two characters that are attacking each other, raises the character if needed

		@param Caster Perpetrator whose height is to be matched
		@param Target The target to match heights with
		@param Time The overwritten time to raise the character for, by default, 1s
	]]
	MatchAirborneHeights: (self: AbilityClass, Agent: Caster, Target: Target, time: number?) -> (),
	
	--[[
		Begin the ability's sequence of events

		@param Caster The one assigned to the casting of the sequence
		@param SequenceFrames Each event inside of the sequence
		@param forceCreationOnly Forces the sequence to not start instantly, and instead be created before started
	]]
	Begin: (self: AbilityClass, Agent: Caster, SequenceFrames: SequenceFrames, forceCreationOnly: boolean?) -> (Sequence),
	Effect: (self: AbilityClass, EffectName: string, ...any) -> (),
	UseAttackData: (self: AbilityClass, Sequence: Sequence, Caster: Caster, Data: {[number]: number}, Hitbox_Data: HitboxAttackData) -> (),

	--[[
		Gets a value from the ability data
		@param Key The key to get from the ability data

		@return The value of the given key, can also be nil
	]]
	FromData: (self: AbilityClass, Key: Default.AbilityDataKey) -> (any),
	SetData: (self: AbilityClass, Data: {}) -> (),

	--[[
		Play a different sequence of effects both on the caster and the target for hitting an enemy.
		@param Caster represents whoever is casting the skill at the time
		@param Target represents whoever is hit by the caster
		@param Data Can include 'EffectData' for modifying the effect, or a Custom HitStopDuration `{ NoHitStop: boolean, StopEffect: boolean, EffectData: {any} }`
	]]
	Hit: (self: AbilityClass, Caster: Caster, Target: Target, Data: {HitstopDuration: number, EffectData: HitVFXData}) -> (),
}

export type DamageHitType = 'Blunt' | 'Slash' | 'None'
export type HitEnemyData = {
	Damage: number,
	Stun: number,
	Daze: number,
	HitType: DamageHitType,
	Affliction: Default.Element,
	Attack_Type: Default.AgentMovesetAbility,
	Affliction_Buildup: number?,
	DontChargeEnergy: boolean,
	DontChargeUlt: boolean,
	HitsAirborne: boolean,
	Airborne: boolean,
	AnimId: number?,

	Knockback: {number | number | number}?,
}

export type AbilityHitRequest = HitEnemyData & {

}

export type MovesetClass = {
	__Passive_Manager: {},
	__Assigned: {[Default.AgentMovesetAbility]: AbilityClass & ServerAbilityClass},

	--
	GetAll: (self: MovesetClass) -> ({ServerAbilityClass}?),
	Assign: (self: MovesetClass, Key: string, Ability: AbilityClass) -> (),
	Verify: (self: MovesetClass, Agent: Caster, Type: string) -> boolean,

	GetPassiveManager: (self: MovesetClass) -> ({
		OnPassiveFilled: (self: any, Id: number, Caster: Caster) -> (),
	}),

	EmulateHooks: (self: MovesetClass, Type: string, State: string, Agent: Caster, Context: {any}) -> (),
	Begin: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster) -> (),
	Release: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster) -> (),
	CancelSkill: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster, Context: {ClientInstruction: boolean?}?) -> (),

	IsOnCooldown: (self: MovesetClass, Agent: Caster, Type: string) -> (boolean),

	GetInfoForSkill: (self: MovesetClass, Name: string) -> {},
	SetAbilityInformation: (self: MovesetClass, Data: {}) -> (),
}

export type MovingHitboxObject = {
	PivotTo: (self: MovingHitboxObject, At: CFrame) -> (),
	GetPivot: (self: MovingHitboxObject) -> (),
	Destroy: (self: MovingHitboxObject) -> (),
	Debug: (self: MovingHitboxObject) -> (),
}

export type AbilityHitInfo = {
	Enemy: Agents.Enemy,
	Caster: {},
	Type: Default.Element,
	Damage: number,
	Burst: boolean,
	IsKill: boolean,
	Hit_Type: 'Entity' | 'Structure',
}
export type InputState = 'Begin' | 'End'
export type SkillContext = {IsSignal: boolean?, Target: Agents.Enemy?, M1_Count: number?, Buffer: { any }}
export type ServerAbilityClass = {
	__Name: string,
	__Skill_Type: number,
	__Cache: {},
	__Signal: RBXScriptSignal,
	__Hit: Default.Signal<AbilityHitInfo>,

	CreateHitbox: (self: ServerAbilityClass, Agent: Caster & CFrame, Offset: Vector3, Size: Vector3, Event: (Enemy: Agents.Enemy) -> ()) -> ({
		Debug: () -> (),
	}),

	Save: (self: ServerAbilityClass, Caster: any, Key: string, Value: any) -> (),
	Get: (self: ServerAbilityClass, Caster: any, Key: string) -> any,
	Increase: (self: ServerAbilityClass, Caster: any, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	ForceRelease: (self: ServerAbilityClass, Caster: Caster) -> (),

	Play: (self: ServerAbilityClass, Agent: Caster, Type: string, State: InputState, Context: SkillContext) -> (),
	Begin: (self: ServerAbilityClass, Agent: Caster, SequenceFrames: SequenceFrames) -> (Sequence),

	Effect: (self: ServerAbilityClass, Name: string, Params: {any}, Targets: boolean | {}) -> (),

	--[[
		Loops through all the other agents in the team, useful for giving buffs, debuffs or applying specific attacks

	]]
	ForOtherAgents: (self: ServerAbilityClass, Agent: Caster, Callback: (Agent: Caster, Data: {IsNext: boolean}) -> ()) -> (),

	--[[
		Hit a target and deal specific amounts of damage and daze.

		@param Caster The one dealing the damage
		@param Enemy The one receiving damage
		@param Hit All the data conforming to the damage to be dealt, along with stun, affliction, etc. See "HitEnemyData"
	]]
	Hit: (self: ServerAbilityClass, Agent: Caster, Enemy: Agents.Enemy, Hit: HitEnemyData) -> ({
		
	}?),

	--[[
		Knock back Character-specific target types, does not affect structures or Agents

		@param Caster The one dealing the knockback
		@param Enemy The one receiving knockback
		@param Hit Data conforming the knockback, [1]: Vector(X, Y, Z) relative to Target, [2]: Strength, [3]: Time
	]]
	KnockBack: (self: ServerAbilityClass, Agent: Caster, Enemy: Agents.Enemy, KnockbackData: {[number]: vector | number}) -> (),

	--[[
		Useful for projectile-like moves, creates a hitbox that moves on its own, for a set amount of time, and at a specific speed.

		@param Caster Exclusively Agents can create hitboxes as of now, as non-agent hitboxes will hit enemies
		@param From CFrame, origin of the projectile and it's direction too
		@param Size Vector3
		@param Speed number Speed in studs/second
		@param Max_Time number The time after which the projectile will disappear
		@param Hit_Function fn(**Target**) -> () The handler of the hit event
	]]
	CreateMovingHitbox: (
		self: ServerAbilityClass, 
		Caster: Caster,
		From: CFrame, 
		Size: vector, 
		Speed: number, 
		Max_Time: number, 
		Hit_Function: (Target: Agents.Enemy) -> ()
	) -> MovingHitboxObject,

	--[[
		@internal
	]]
	UseAttackData: (self: ServerAbilityClass, Sequence: Sequence, Caster: Caster, Data: {[number]: number}, Hitbox_Data: HitboxAttackData) -> (),

	FromData: (self: ServerAbilityClass, Key: Default.AbilityDataKey, SubKey: string?, Level: number?) -> (any),
	
	--[[
		@internal
	]]
	SetData: (self: ServerAbilityClass, Data: {}) -> (),
}

return {
	CHARACTER_STATES = {
		Attacking = 'Attacking',
		Idle = 'Idle',
		Stunned = 'Stunned',
		Dashing = 'Dashing',
		Airborne = 'Airborne',
		Frozen = 'Frozen',
	}
}