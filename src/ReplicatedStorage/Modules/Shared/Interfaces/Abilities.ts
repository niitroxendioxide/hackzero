import { ServerAgentClass, ClientAgentClass, ServerEnemyClass, Character } from "./Characters";

/* Local Types (just not necessary to export these) */
type SkillCaster = ServerAgentClass | ServerEnemyClass
type KnockbackData = [vector, number, number];

/* Might be used for other stuff later, export */
export type SequenceFrames = [
    [number, () => void] | [number, number, () => void] 
]
export interface Sequence {
    __currentTime: number,
}

export type TargetHitData = {
    Damage: number,
    Daze: number,
    Stun: number,
    CanChainAttack?: boolean,
    DontChargeEnergy?: boolean,
    DontChargeUlt?: boolean,
    HitsAirborne?: boolean,
    Airborne?: boolean,
    NoRotate?: boolean,
    AnimId?: number,

    Knockback: KnockbackData,
    HitType?: string,
    Affliction?: string,
    Affliction_Buildup?: number,
}

export type AbilityHitResult = {
    Enemy: ServerEnemyClass,
    Caster: ServerAgentClass,
    CanChainAttack: boolean,
    Type?: string,
    Damage: number,
    Burst: boolean,
    IsKill: boolean,
    Hit_Type: 'Entity' | 'Structure',
}

export interface ServerAbility {
    Name: string,
    __Name: string,
    __Skill_Type: number,
    __Cache: {},
    __Signal: RBXScriptSignal,
    __Hit: RBXScriptSignal,

    Begin(Caster: SkillCaster, Frames: SequenceFrames, CreateOnly?: boolean): void,
    CreateHitbox(Caster: SkillCaster, Offset: vector, Size: vector, Event: (Enemy: SkillCaster) => void): void,
    CreateMovingHitbox(
        Caster: SkillCaster, 
        From: CFrame, 
        Size: vector,
         Speed: number, 
        Max_Time: number, 
        Hit_Function: (Target: ServerEnemyClass) => void
    ): void, 

    Get(Caster: SkillCaster, Key: string): any,
    Save(Caster: SkillCaster, Key: string, Value: any): void,
    Increase(Caster: SkillCaster, Data: {}): void,

    OnCancel(): void,
    ForOtherAgents(): void,
    ForceRelease(): void,

    KnockBack(Agent: SkillCaster, Enemy: ServerEnemyClass, Data: KnockbackData): void,

    Hit(Caster: SkillCaster, Target: ServerEnemyClass, Hit: TargetHitData): AbilityHitResult,
    FromData(Key: string, Sub_Key?: string, Level?: number, Default?: any): any,

}