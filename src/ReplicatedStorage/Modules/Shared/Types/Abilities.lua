local Default = require(script.Parent)
local Agents = require(script.Parent.Agents)

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

	Add: (self: Sequence, Time: number, fn: (self: Sequence) -> ()) -> (),
}

export type HitboxAttackData = {Size: Vector3, Offset: Vector3, Hit_Function: (Target: any) -> ()}


export type Caster = Agents.ServerAgentClass & Agents.AgentClass & Agents.Enemy & Agents.ClientEnemy
export type Target = Caster

export type AbilityClass = {
	__Cache: {},
	__Signal: RBXScriptSignal,
	__Cooldown: any,
	__Name: string,
	Name: string,

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
	PlayAnimation: (self: AbilityClass, Agent: Caster, Track: string, Data: {
		Fade: number?,
		Speed: number?,
		Weight: number?,
		Active_Time: number?,
	}) -> (),
	CreateHitbox: (self: AbilityClass, Agent: Caster, Offset: Vector3, Size: Vector3, Event: (Enemy: Agents.ClientEnemy) -> ()) -> (),

	Save: (self: AbilityClass, Agent: Caster, Key: string, Value: any) -> (),
	Get: <T>(self: AbilityClass, Agent: Caster, Key: string) -> T,
	Increase: (self: AbilityClass, Agent: Caster, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	Play: (self: AbilityClass, Agent: Caster, Type: string, State: 'Begin' | 'End', Other: {any}) -> (),
	Begin: (self: AbilityClass, Agent: Caster, SequenceFrames: SequenceFrames) -> (Sequence),
	Effect: (self: AbilityClass, EffectName: string, ...any) -> (),
	UseAttackData: (self: AbilityClass, Sequence: Sequence, Caster: Caster, Data: {[number]: number}, Hitbox_Data: HitboxAttackData) -> (),

	--[[
		Gets a value from the ability data
		@param Key The key to get from the ability data

		@return The value of the given key, can also be nil
	]]
	FromData: (self: AbilityClass, Key: Default.AbilityDataKey) -> (any),
	SetData: (self: AbilityClass, Data: {}) -> (),
}

export type HitEnemyData = {
	Damage: number,
	Stun: number,
	Daze: number,
	Affliction: Default.Element,
	Attack_Type: Default.AgentMovesetAbility,
	Affliction_Buildup: number?,
	DontChargeEnergy: boolean,
	DontChargeUlt: boolean,

	Knockback: {number | number | number}?,
}

export type AbilityHitRequest = HitEnemyData & {

}

export type MovesetClass = {
	__Assigned: {[Default.AgentMovesetAbility]: AbilityClass & ServerAbilityClass},

	--
	GetAll: (self: MovesetClass) -> ({ServerAbilityClass}?),
	Assign: (self: MovesetClass, Key: string, Ability: AbilityClass) -> (),
	Verify: (self: MovesetClass, Agent: Caster, Type: string) -> boolean,

	Begin: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster) -> (),
	Release: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster) -> (),
	CancelSkill: (self: MovesetClass, Key: Default.AgentMovesetAbility, Agent: Caster, Context: {ClientInstruction: boolean?}?) -> (),

	GetInfoForSkill: (self: MovesetClass, Name: string) -> {},
	SetAbilityInformation: (self: MovesetClass, Data: {}) -> (),
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
export type SkillContext = {IsSignal: boolean?, Target: Agents.Enemy?}
export type ServerAbilityClass = {
	__Name: string,
	__Cache: {},
	__Signal: RBXScriptSignal,
	__Hit: Default.Signal<AbilityHitInfo>,

	CreateHitbox: (self: ServerAbilityClass, Agent: Caster, Offset: Vector3, Size: Vector3, Event: (Enemy: Agents.Enemy) -> ()) -> (),

	Save: (self: ServerAbilityClass, Caster: any, Key: string, Value: any) -> (),
	Get: (self: ServerAbilityClass, Caster: any, Key: string) -> any,
	Increase: (self: ServerAbilityClass, Caster: any, Key: string, Data: {Rate: number, Limit: number}?) -> (),

	ForceRelease: (self: ServerAbilityClass, Caster: Caster) -> (),

	Play: (self: ServerAbilityClass, Agent: Caster, Type: string, State: InputState, Context: SkillContext) -> (),
	Begin: (self: ServerAbilityClass, Agent: Caster, SequenceFrames: SequenceFrames) -> (Sequence),

	Effect: (self: ServerAbilityClass, Name: string, Params: {any}, Targets: boolean | {}) -> (),
	ForOtherAgents: (self: ServerAbilityClass, Agent: Caster, Callback: (Agent: Caster, Data: {IsNext: boolean}) -> ()) -> (),
	Hit: (self: ServerAbilityClass, Agent: Caster, Enemy: Agents.Enemy, Hit: HitEnemyData) -> (number),

	UseAttackData: (self: ServerAbilityClass, Sequence: Sequence, Caster: Caster, Data: {[number]: number}, Hitbox_Data: HitboxAttackData) -> (),

	FromData: (self: ServerAbilityClass, Key: Default.AbilityDataKey, SubKey: string?, Level: number?) -> (any),
	SetData: (self: ServerAbilityClass, Data: {}) -> (),
}

return 0