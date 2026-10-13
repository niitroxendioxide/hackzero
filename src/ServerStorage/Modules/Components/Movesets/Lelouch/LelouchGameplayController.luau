---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

local Table = require(Shared.Utility.Table)
local AgentTypes = require(Shared.Types.Agents)
local AbilityTypes = require(Shared.Types.Abilities)
local EnemyLibrary = require(Shared.Libraries.Enemies)
local EnemyDatabase = require(Shared.Database.Enemies)
local CharacterDatabase = require(Shared.Database.Characters)
local Replicator = require(Modules.Libraries.Replicator)
local AgentLibrary = require(Modules.Libraries.Agents)
local AbilityClass = require(Modules.Classes.Combat.ServerAbility)
local TurretClass = require(Modules.Classes.Combat.ServerTurret)

---
const METER_NAME = 'Checkmate'
const BLIND_TAG = 'Blinded'
const FLASHED_TAG = 'Flashed'
const SUBJUGATED_TAG = 'Subjugated'
const PARALYZE_IMMUNE_TAG = 'LelouchParalyzeImmune'

const HIT_EFFECT_DATA = {
    Highlight = true,
    HighlightColor = Color3.fromRGB(171, 97, 255),
}

const KNIGHT_OFFSETS = {
    CFrame.new(-4, 0, 3),
    CFrame.new(4, 0, 3),
    CFrame.new(-7, 0, 0),
    CFrame.new(7, 0, 0),
    CFrame.new(0, 0, 5),
}

const PassiveData = CharacterDatabase:GetMovesetData('Lelouch').Passive
const KnightData = PassiveData.Black_Knights
const GrenadeData = PassiveData.Grenade
const KnightmareData = PassiveData.Knightmares

const TurretAbility = AbilityClass.new()

---
const Controller = {
    __Knights = {} :: { [AgentTypes.ServerAgentClass]: { any } },
    __Knight_Slot = {} :: { [AgentTypes.ServerAgentClass]: number },
    __Targets = {} :: { [AgentTypes.ServerAgentClass]: AbilityTypes.ServerEnemy },
    __Focus = {} :: { [AgentTypes.ServerAgentClass]: boolean },
    __Commands = setmetatable({}, { __mode = 'k' }) :: { [AbilityTypes.ServerEnemy]: number },
}

local function IsEnemy(Target: any): boolean
    return tostring(Target) == 'EnemyClass'
end

local function MarkCommand(Enemy: AbilityTypes.ServerEnemy, Time: number)
    Controller.__Commands[Enemy] = math.max(Controller.__Commands[Enemy] or 0, os.clock() + Time)
end

function Controller:IsValidTarget(Target: any): boolean
    return IsEnemy(Target) and Target:IsAlive() and EnemyLibrary:GetEnemy(Target:GetId()) == Target
end

function Controller:IsNormal(Enemy: any): boolean
    if not IsEnemy(Enemy) then
        return true
    end

    const EnemyData = EnemyDatabase:GetEnemyData(Enemy.__Name)
    if EnemyData == nil then
        return true
    end

    return not (EnemyData.Is_Boss == true or EnemyData.EnemyTier == 'Boss' or EnemyData.EnemyTier == 'Elite')
end

function Controller:ReplicateHit(Enemy: AbilityTypes.ServerEnemy)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Replicator:Effect('Hit', {Enemy:GetId(), HIT_EFFECT_DATA}, true)
end

function Controller:GetStrategy(Caster: AgentTypes.ServerAgentClass)
    local Strategy = {
        Element = 'Physical',
        Affliction = false,
        Flashbang = false,
    }

    const ReplicationId = Caster.__Player_Assigned:GetAttribute('ReplicationId')
    for _, Agent in AgentLibrary:GetAll(ReplicationId) do
        if Agent == Caster then
            continue
        end

        const AgentData = CharacterDatabase:GetCharacterData(Agent.Name)
        if AgentData.Role == 'Affliction' and not Strategy.Affliction then
            Strategy.Affliction = true
            Strategy.Element = AgentData.Element
        elseif AgentData.Role == 'Stun' then
            Strategy.Flashbang = true
        end
    end

    return Strategy
end

function Controller:ApplyStrategy(Caster: AgentTypes.ServerAgentClass, HitData: AbilityTypes.HitEnemyData)
    const Strategy = Controller:GetStrategy(Caster)
    const NewData = Table.CopyDeep(HitData)

    if Strategy.Affliction then
        NewData.Affliction = Strategy.Element
        NewData.Forced_Affliction = true
    end

    return NewData, Strategy
end

function Controller:SetTarget(Caster: AgentTypes.ServerAgentClass, Target: any)
    if Controller:IsValidTarget(Target) then
        Controller.__Targets[Caster] = Target
    end
end

function Controller:GetTarget(Caster: AgentTypes.ServerAgentClass): AbilityTypes.ServerEnemy?
    const Target = Controller.__Targets[Caster]
    if Controller:IsValidTarget(Target) then
        return Target
    end

    Controller.__Targets[Caster] = nil

    return nil
end

function Controller:GetTargetInRange(Caster: AgentTypes.ServerAgentClass, Target: any, Range: number): AbilityTypes.ServerEnemy?
    if not Controller:IsValidTarget(Target) then
        return nil
    end

    if (Target:GetPivot().Position - Caster:GetPivot().Position).Magnitude > Range then
        return nil
    end

    Controller.__Targets[Caster] = Target

    return Target
end

local function GetTurretTarget(Caster: AgentTypes.ServerAgentClass, Turret: any, Range: number)
    if not Caster:IsAlive() then
        return nil
    end

    const Target = Controller:GetTarget(Caster)
    if Target and Turret:IsInRange(Target) then
        return Target
    end

    const _, Nearest = EnemyLibrary:GetNearestEnemy(Turret:GetPivot().Position, Range)

    return Nearest
end

local function KnightFire(Caster: AgentTypes.ServerAgentClass, Target: AbilityTypes.ServerEnemy)
    const HitData = Controller:ApplyStrategy(Caster, KnightData.Hit)
    if Controller.__Focus[Caster] then
        HitData.Daze *= KnightData.Focus_Daze_Multiplier
    end

    TurretAbility:Hit(Caster, Target, HitData)
    Controller:ReplicateHit(Target)
end

function Controller:SummonKnights(Caster: AgentTypes.ServerAgentClass, Count: number, Origin: CFrame?)
    if not Controller.__Knights[Caster] then
        Controller.__Knights[Caster] = {}
    end

    const Knights = Controller.__Knights[Caster]
    const At = Origin or Caster:GetPivot()

    for _ = 1, Count do
        if #Knights >= KnightData.Max then
            table.remove(Knights, 1):Destroy()
        end

        const Slot = (Controller.__Knight_Slot[Caster] or 0) % #KNIGHT_OFFSETS + 1
        Controller.__Knight_Slot[Caster] = Slot

        const Knight = TurretClass.new(Caster, At * KNIGHT_OFFSETS[Slot], {
            Lifetime = KnightData.Lifetime,
            Range = KnightData.Range,
            Interval = if Controller.__Focus[Caster] then KnightData.Focus_Interval else KnightData.Interval,
            Size = KnightData.Size,
        })

        Knight.Destroyed:Connect(function()
            const Index = table.find(Knights, Knight)
            if Index then
                table.remove(Knights, Index)
            end

            Caster:UpdateMeter(METER_NAME, 1)
        end)

        Knight:Start(function(Turret)
            return GetTurretTarget(Caster, Turret, KnightData.Range)
        end, function(_, Target)
            KnightFire(Caster, Target)
        end)

        table.insert(Knights, Knight)
    end
end

function Controller:GetKnightCount(Caster: AgentTypes.ServerAgentClass): number
    return #(Controller.__Knights[Caster] or {})
end

function Controller:SetFocusFire(Caster: AgentTypes.ServerAgentClass, State: boolean)
    Controller.__Focus[Caster] = if State then true else nil

    for _, Knight in Controller.__Knights[Caster] or {} do
        Knight:SetInterval(if State then KnightData.Focus_Interval else KnightData.Interval)
    end
end

function Controller:Volley(Caster: AgentTypes.ServerAgentClass, Target: any)
    for _, Knight in Controller.__Knights[Caster] or {} do
        const KnightTarget = if Knight:CanFireAt(Target) then Target else GetTurretTarget(Caster, Knight, KnightData.Range)

        if Knight:CanFireAt(KnightTarget) then
            KnightFire(Caster, KnightTarget)
        end
    end
end

function Controller:SpawnKnightmares(Caster: AgentTypes.ServerAgentClass, Ability: AbilityTypes.ServerAbilityClass, Count: number, Data: {
    Lifetime: number,
    Interval: number,
    Hit: AbilityTypes.HitEnemyData,
    Blast_Size: vector,
    Use_Strategy: boolean?,
})
    const At = Caster:GetPivot()

    for Index = 1, Count do
        const Angle = math.rad(KnightmareData.Spread * (Index - (Count + 1) / 2))
        const Knightmare = TurretClass.new(Caster, At * CFrame.Angles(0, Angle, 0) * CFrame.new(0, 0, KnightmareData.Distance), {
            Lifetime = Data.Lifetime,
            Range = KnightmareData.Range,
            Interval = Data.Interval,
            Size = KnightmareData.Size,
        })

        Knightmare:Start(function(Turret)
            return GetTurretTarget(Caster, Turret, KnightmareData.Range)
        end, function(_, Target)
            const HitData = if Data.Use_Strategy then Controller:ApplyStrategy(Caster, Data.Hit) else Data.Hit

            Ability:CreateHitbox(Target:GetPivot(), vector.zero, Data.Blast_Size, function(Enemy)
                Ability:Hit(Caster, Enemy, HitData)
                Controller:ReplicateHit(Enemy)
            end, nil, nil, Caster)
        end)
    end
end

function Controller:ThrowGrenade(Caster: AgentTypes.ServerAgentClass, At: CFrame, HitData: AbilityTypes.HitEnemyData, Ability: AbilityTypes.ServerAbilityClass?)
    const GrenadeAbility = Ability or TurretAbility
    const NewData, Strategy = Controller:ApplyStrategy(Caster, HitData)

    if Strategy.Flashbang then
        NewData.Daze *= GrenadeData.Flashbang_Daze_Multiplier
    end

    GrenadeAbility:CreateHitbox(At, vector.zero, GrenadeData.Size, function(Enemy)
        GrenadeAbility:Hit(Caster, Enemy, NewData)

        if Strategy.Flashbang then
            Controller:Flash(Enemy)
        end
    end, nil, nil, Caster)

    return Strategy
end

function Controller:Flash(Enemy: AbilityTypes.ServerEnemy)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddEffect({
        Tag = FLASHED_TAG,
        Type = 'Critical_Rate_Taken',
        Value = GrenadeData.Flashbang_Crit_Rate,
        Time = GrenadeData.Flashbang_Time,
        Unique = true,
    })

    Enemy:AddTag(FLASHED_TAG, GrenadeData.Flashbang_Time)
end

function Controller:HasCommand(Enemy: AbilityTypes.ServerEnemy): boolean
    return (Controller.__Commands[Enemy] or 0) > os.clock()
end

function Controller:StandStill(Enemy: AbilityTypes.ServerEnemy, Slow: number, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddEffect({
        Tag = 'LelouchStandStill',
        Type = 'Speed',
        Value = Slow,
        Time = Time,
        Unique = true,
    })

    MarkCommand(Enemy, Time)
end

function Controller:Yield(Enemy: AbilityTypes.ServerEnemy, Percent: number, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddEffect({
        Tag = 'LelouchYield',
        Type = 'Defense',
        Value = `-{Percent}%`,
        Time = Time,
        Unique = true,
    })

    MarkCommand(Enemy, Time)
end

function Controller:ShredResistance(Enemy: AbilityTypes.ServerEnemy, Element: string, Value: number, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddEffect({
        Tag = 'LelouchResistanceShred',
        Type = 'RES_' .. Element,
        Value = Value,
        Time = Time,
        Unique = true,
    })
end

function Controller:Paralyze(Enemy: AbilityTypes.ServerEnemy, Time: number, Immunity_Time: number): boolean
    if not Controller:IsValidTarget(Enemy) or Enemy:HasTag(PARALYZE_IMMUNE_TAG) then
        return false
    end

    Enemy:ApplyTrueStun(Time)
    Enemy:AddTag(PARALYZE_IMMUNE_TAG, Immunity_Time)

    MarkCommand(Enemy, Time)

    return true
end

function Controller:Blind(Enemy: AbilityTypes.ServerEnemy, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddTag(BLIND_TAG, Time)

    MarkCommand(Enemy, Time)
end

function Controller:Kneel(Enemy: AbilityTypes.ServerEnemy, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:ApplyTrueStun(Time)

    MarkCommand(Enemy, Time)
end

function Controller:Subjugate(Enemy: AbilityTypes.ServerEnemy, Damage_Taken: number, Affliction_Taken: number, Time: number)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy:AddEffect({
        Tag = 'LelouchSubjugateDamage',
        Type = 'Damage_Taken',
        Value = Damage_Taken,
        Time = Time,
        Unique = true,
    })

    Enemy:AddEffect({
        Tag = 'LelouchSubjugateAffliction',
        Type = 'Affliction_Buildup_Taken',
        Value = Affliction_Taken,
        Time = Time,
        Unique = true,
    })

    Enemy:AddTag(SUBJUGATED_TAG, Time)

    MarkCommand(Enemy, Time)
end

function Controller:ForceAffliction(Enemy: AbilityTypes.ServerEnemy, Element: string)
    if not Controller:IsValidTarget(Enemy) then
        return
    end

    Enemy.__Status.__AfflictionMeter[Element] = 100
end

return Controller
