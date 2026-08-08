local AbilityTypes = require(script.Parent.Abilities)


export type PatternData = {
    -- Skill list, in order of usage.
    Skills: { string },
    
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

    Phase: (Name: string, Condition: () -> ()) -> (),
    DefinePattern: (Name: string, Pattern: PatternData) -> (),

    SetBasePatterns: (PatternList: { PatternOption }) -> (),
    SetPatterns: (Phase: string, PatternList: { PatternOption }) -> (),

    OnPatternUsed: () -> (),
}

export type EntityState = {
    Health: number,
    HealthPercent: number,

}

return 0