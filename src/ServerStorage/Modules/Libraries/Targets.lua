local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Shared = ReplicatedStorage.Modules.Shared
local Statics = require(Shared.Database.Statics)

local SAME_ATTACKER = 1.25
local DIFFERENT_ATTACKER = 1

--
local Hits = {}
local Targets = {
    __Current_Difficulty = 'EASY',
}

function Targets:SetDifficulty(Difficulty: string)
    local DifficultyVariables = Statics.Difficulty_Targetting_Priorities[Difficulty]
    if not DifficultyVariables then
        return
    end

    Targets.__Current_Difficulty = Difficulty
    SAME_ATTACKER = DifficultyVariables.SAME_ATTACKER
    DIFFERENT_ATTACKER = DifficultyVariables.DIFFERENT_ATTACKER
end

function Targets:RefreshLastAttackedTime(Target: any, Attacker: any)
    if not Hits[Target] then
        Hits[Target] = {
            Last = os.clock(),
            Attacker = Attacker
        }
    end

    Hits[Target].Last = os.clock()
    Hits[Target].Attacker = Attacker
end

function Targets:CanAttackTarget(Target: any, Attacker: any)
    if (string.lower(Targets.__Current_Difficulty) == 'passive') then
        return false
    end

    if not Hits[Target] then
        return true
    end

    local TimeSinceLastHit = os.clock() - Hits[Target].Last

    if TimeSinceLastHit < SAME_ATTACKER and Hits[Target].Attacker == Attacker then
        return false
    end

    return TimeSinceLastHit > DIFFERENT_ATTACKER
end

return Targets