local AbilityTypes = require(script.Parent.Abilities)


export type PatternData = {
    -- Skill list, in order of usage.
    Skills: { string },
    
    CooldownTime: number,
    Cooldown: number?,
    MaxChainUsages: number?,
    SkillsRandomized: boolean,

    -- Whether the sequence can be interrupted by causing dazed state on the opponent
    Interruptible: boolean,
}

export type PatternOption = {
    Once: boolean,
    Name: string,
    Weight: number,
}

export type EntityEvent = "";

export type EntityBehavior = {
    When: (Event: EntityEvent, fn: (Entity: AbilityTypes.ServerEnemy) -> ()) -> (),

    Phase: (Name: string, Priority: number, Condition: () -> ()) -> (),
    DefinePattern: (Name: string, Pattern: PatternData) -> (),

    SetBasePatterns: (PatternList: { PatternOption }) -> (),
    SetPatterns: (Phase: string, PatternList: { PatternOption }) -> (),

    OnPatternUsed: (PatterName: string, Handler: () -> ()) -> (),
}

export type EntityState = {
    Health: () -> (number),
    HealthPercent: () -> (number),
}

export type EntityBehaviorState = {
    EntityId: number,
    PhaseCount: number,
    LastUpdate: number,

    RanPhases: {
        [string]: boolean,
    },
    
    Cooldowns: {
        [string]: { Time: number, Turns: number, }
    },
    Skills: {
        [string]: boolean,
    },
    OncePatterns: {[string]: boolean},
    LastUsedPattern: {
        Name: string,
        UseCount: number,
    },
    CurrentPattern: string,
    PatternProgress: number,
    CurrentPhase: {
        Name: string,
        Priority: number,
    },


    Phases: {
        [string]: {
            Priority: number,
            Condition: () -> (boolean)
        },
    },
    Patterns: { [string]: PatternData },
    PatternRanges: {
        { string | number }
    },
    Events: {
        {Type: number, Data: { any }}
    },
    PhasePatterns: {
        [string]: { PatternOption }
    },
}

return 0