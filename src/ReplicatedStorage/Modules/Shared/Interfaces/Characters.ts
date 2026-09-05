import "@rbxts/types"


export interface AgentItemsClass {};

export interface ClientGearManager {};
export interface ServerGearManager {};

export interface AgentStatusClass {};
export type SkillLevels = { [key: string]: number };
export type AssistStruct = {};

export type CurrentTarget = {
    Data: AssistStruct, 
    Thread: thread
};

export type EffectParameters = {
    Tag?: string,
    Time?: number,
    Value?: number,
    Values?: [number];
    Types?: [string],
    Type?: string,
    Amount?: number,
    Unique?: boolean,
    Base_Amount?: number,
    Hide?: boolean,
}

export interface EffectObject {
    Tag: string,
    Time: number,
    Value: [number] | number,
    Type: string | [string],
    Amount: number,
    Id: number,
    Thread: thread,
    Limit: number,
    Created: number,
    Hide: boolean,

    Remove(): void,
}

export type AgentMeter = {
    Id?: number,
    [key: string]: any,
}

export interface Character {
    Init(): void,
    Move(): void,
    Look(): void,
    GetPivot(): CFrame,
    PivotTo(At: CFrame): void,

    Update(delta: number): void,
    SwitchState(State: string, Time: number): void,

    IsMoving(): boolean,
    IsAlive(): boolean,
    IsAirborne(): boolean,

    AddTag(Tag: string, Time?: number): void,
    HasTag(Tag: string): boolean,
    RemoveTag(Tag: string): void, 

    GetId(): number,
    Destroy(): void,
}

export interface ClientEnemyClass extends Character {
    
}
export interface ServerEnemyClass extends Character {
    __Name: string,
    __Status: any,
    __EnemyId: number,

    IsFrozen(): boolean,
    IsTrueStun(): boolean,
    IsAbilityMoving(): boolean,
    IsGrabbed(): boolean,
    
    Stun(Time: number, UsingAirborne?: boolean): void,
    TakeDaze(Amount: number): boolean,
    TakeDamage(Amount: number): void,

    TakeAffliction(Amount: number): void,
    ResetAffliction(): number,
    GetAfflictionStackedDamage(): number,
    GetAfflictionType(): string,
    Rotate(): void

    GetTarget(): ServerAgentClass | void,
    GetState(): string,
    GetHealth(): number,
    GetStat(Stat: string): number,
}

export interface ClientAgentClass extends Character {
    Name: string,
    PlayerId: number,

    __Level: number,
    __User: number,
    __Skill_Thread: thread,
    __Player_Assigned: Player,
    __Items: any,
    __Gear: any,
    __Locked: boolean,
    __Skill_Levels: SkillLevels,
    __Limit_Area: BasePart,
    __Listener_Count: number,
    __Server_Action_Buffer: { [key: number]: number },
    __current_walking_object?: any,
    __Current_Collision_Priority: number,
    __Tags: { [key: string]: thread },

    SetLimitArea(Part: BasePart): void,
    GetLimitArea(): BasePart,

    IsActive(): boolean,
    CanSwitch(): boolean,
    GetHitbox(): BasePart,
    LookAtTarget(): void,
    GetModel(): Model,

    Land(): void,
}
export interface ServerAgentClass extends Character {
    Name: string,
    __Level: number,
	__User: number,
	__Ascension: number,
	__Main_Thread?: thread,
	__Player_Assigned: Player,
	__Status: AgentStatusClass,
	__Items: AgentItemsClass,
	__Skill_Levels: SkillLevels,
	__Last_Skill_Cast: number,
	__Last_Hit_Time: number,
	__Last_Hit_Caster: number,
	__Current_Target?: CurrentTarget,
	__Gear: ServerGearManager,
	__Limit_Area?: BasePart,
	__current_walking_object?: any,
	__Meter_updates: {},
	__Current_Collision_Priority?: number,

    SetLimitArea(Part: BasePart): void,
    GetLimitArea(): BasePart,

    IsActive(): boolean,
    SetActive(State: boolean): void,
    
    UpdateMeter(Name: string, Amount: number): void,
    CreateMeter(): void,
    GetMeter(): [number, number],
    GetAllMeters(): { [key: number]: AgentMeter },
    
    GetCurrentSkil(): string,
    SetCurrentSkill(State: string, Time?: number): void,
    
    ImpulseForward(Power: number, FadeOutTime: number): void,
    ApplyImpulse(Velocity: vector): void,
    
    Walk(Time: number, Power?: number, Linear?: boolean): void,
    
    GetHitbox(): BasePart,
    GetEnergy(): number,
    GetStat(): number,
    GetState(): string,
    GetSkillLevel(SkillName: string): number,
    
    Hit(Caster: ServerEnemyClass, Time: number): void,
    TakeDamage(Amount: number): void,
    Heal(Amount: number): void,

    AddEffect(Data: EffectParameters): EffectObject,
    GetEffect(Tag: string): EffectObject,
    ChangeEffect(Tag: string, Amount?: number, RestartThread?: boolean): EffectObject,
    RemoveEffect(Id: number): void,
    RefreshEffect(Tag: string): void,
}