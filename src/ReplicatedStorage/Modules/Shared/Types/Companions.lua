local Agents = require(script.Parent.Agents)
local Default = require(script.Parent)
local Abilities = require(script.Parent.Abilities)


export type ClientCompanionClass = {
    __Key: number?,
    __Collider: BasePart,
    __Appearance: Default.AppearanceController,
    __Goal: CFrame,
    __Connection: RBXScriptConnection?,
    __Alpha: number,
    __Animator: {[string]: any},
    __Moving: boolean,

    GetId: (self: ClientCompanionClass) -> (number?),

    Init: (self: ClientCompanionClass, Key: number) -> (),
    Move: (self: ClientCompanionClass, Position: vector) -> (),
}

export type CompanionClass = {
    __Connection: RBXScriptConnection,
    __Movement: CompanionMovementClass,
    __Owner: Agents.AgentClass | Agents.ServerAgentClass,
    __Level: number,
    __Stats: CompanionStatsClass,
    __Key: number,
    __Moving: boolean,
    __Last_Attack_Time: number,
    __Thread: thread?,
    __State: 'Idle' | 'Attacking' | string,
    __Name: string,

    --[[
        Set the player to follow by default. When no area is set, the robot follows this character
        @param Box **BasePart** The area that the companion will be limited to
    ]]
    Follow: (self: CompanionClass, AgentToFollow: Agents.AgentClass | Agents.ServerAgentClass) -> (),
    AddGear: (self: CompanionClass, Gear: Agents.GearObject) -> (),
    GetOwner: (self: CompanionClass) -> (Agents.AgentClass | Agents.ServerAgentClass),
    RemoveGear: (self: CompanionClass, Gear: Agents.GearObject) -> (),
    PivotTo: (self: CompanionClass, At: CFrame) -> (),
    GetPivot: (self: CompanionClass) -> (CFrame),
    ComputeActions: (self: CompanionClass, Delta: number) -> (),
    Attack: (self: CompanionClass) -> (),
    GetGearManager: (self: CompanionClass) -> (Agents.ServerGearManager),

    --[[
        Set the area for the companion to wander around
        @param Box **BasePart** The area that the companion will be limited to
    ]]
    SetAreaDelimiter: (self: CompanionClass, Box: BasePart) -> (),
    Init: (self: CompanionClass, Id: number) -> (),

    --Update: (self: CompanionClass, Delta: number) -> (),

    GetStat: (self: CompanionClass, Stat: string) -> (number),

}

export type CompanionStatsClass = {
    __Items: {Agents.GearObject},
    __Stats: {
        Attack: number,
        Defense: number,
        Speed: number,
    },

    GetStat: (self: CompanionStatsClass, Stat: string) -> (number?),
    Add: (self: CompanionStatsClass, Item: any) -> (),
    Remove: (self: CompanionStatsClass, Item: any) -> (),
}

export type CompanionStats = {
    Attack: number,
    AttackRate: number,
    AttackSpeed: number,
    Defense: number,
    Speed: number,
}

export type Rarities = {
        Base: {[string]: number},
        Level: {[string]: number},
}
export type CompanionData = {
    Id: string,
    Level: number,
    Experience: number,
    Trait: string,
    BaseStats: CompanionStats,
    LevelStats: CompanionStats,

    StatsRarity: Rarities,

    ObtainmentDate: number,
}

export type ClientCompanionData = {
    Id: string,
    Name: string,
    Level: number,
    Trait: string,
    Experience: number,

    Stats: CompanionStats,
    Rarities: Rarities,
}

export type CompanionMovementClass = {
    __Area: BasePart?,
    __Clock: number,
    __Speed: number,
    __Moving: boolean,
    __Collider: BasePart,
    __Can_Move: boolean,
    __Follow_Object: (Agents.AgentClass | Agents.ServerAgentClass)?,
    __Movement_Length: number,

    __Goal: vector | Vector3,
    __Position: vector | Vector3,
    __Direction: vector | Vector3,

    Update: (self: CompanionMovementClass, Delta: number) -> (),
    IsMoving: (self: CompanionMovementClass) -> (boolean),

    SetArea: (self: CompanionMovementClass, Box: BasePart?) -> (),
    Follow: (self: CompanionMovementClass, Agent: Agents.AgentClass | Agents.ServerAgentClass) -> (),

    CreateCollider: (self: CompanionMovementClass) -> (BasePart),
    GetCollider: (self: CompanionMovementClass) -> (BasePart),
    GetPivot: (self: CompanionMovementClass) -> (CFrame),
    GetGoal: (self: CompanionMovementClass) -> (CFrame),
    PivotTo: (self: CompanionMovementClass, At: CFrame) -> (),
}

export type PlayerCompanionDataClass = {
    __Id: string,
    __Level: number,
    __Base_Stats: {},
    __Level_Stats: {},


    ToData: (self: PlayerCompanionDataClass) -> (CompanionData),
    Compress: (self: PlayerCompanionDataClass) -> (string, buffer),
}


export type CompanionAttackData = {
    HitboxArea: (vector | Vector3)?,

    Damage: number,
    Element: string?,
    Affliction: number?,

}
export type ServerCompanionAttack = {
    __Cache: {[any]: {[string]: any}},
    __Sequences: {[CompanionClass]: Abilities.Sequence},

    Run: (self: ServerCompanionAttack, Caster: CompanionClass, Target: Agents.Enemy) -> (),
    Cancel: (self: ServerCompanionAttack, Caster: CompanionClass) -> (),


    Sequence: (self: ServerCompanionAttack, Caster: CompanionClass, Frames: Abilities.SequenceFrames) -> (),
    Save: (self: ServerCompanionAttack) -> (),

    Hit: (self: ServerCompanionAttack, Target: Agents.Enemy, HitData: {}) -> (),
}

return 0