---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

local GameEnum = require(Shared.GameEnum)
local Heap = require(Shared.Utility.Heap)
local Table = require(Shared.Utility.Table)
local AgentTypes = require(Shared.Types.Agents)
local AbilityTypes = require(Shared.Types.Abilities)
local EnemyLibrary = require(Shared.Libraries.Enemies)
local CharacterDatabase = require(Shared.Database.Characters)
local Replicator = require(Modules.Libraries.Replicator)
local AgentLibrary = require(Modules.Libraries.Agents)
local AbilityClass = require(Modules.Classes.Combat.ServerAbility)
local TurretClass = require(Modules.Classes.Combat.ServerTurret)

---
const KNIGHT_ID_OFFSET = 256

const KNIGHT_OFFSETS = {
    CFrame.new(-6, 0, 4),
    CFrame.new(6, 0, 4),
    CFrame.new(-7, 0, -1),
    CFrame.new(7, 0, -1),
    CFrame.new(0, 0, 6),
}

const KnightData = CharacterDatabase:GetMovesetData('Lelouch').Passive.Black_Knights
const KnightAbility = AbilityClass.new()

type Knight = {
    Id: number,
    Turret: any,
}

type AgentKnights = {
    IdHeap: Heap.Heap,
    Knights: { [number]: Knight },
}

---
const Controller = {
    __Agents = {} :: { [AgentTypes.ServerAgentClass]: AgentKnights },
    __Targets = {} :: { [AgentTypes.ServerAgentClass]: AbilityTypes.ServerEnemy },
    __Commands = {} :: { [AgentTypes.ServerAgentClass]: { [AbilityTypes.ServerEnemy]: {CommandData} } }
}

local function GetAgentKnights(Caster: AgentTypes.ServerAgentClass): AgentKnights
    if not Controller.__Agents[Caster] then
        Controller.__Agents[Caster] = {
            IdHeap = Heap.new(KnightData.Max),
            Knights = {},
        }
    end

    return Controller.__Agents[Caster]
end

local function GetNetworkId(Caster: AgentTypes.ServerAgentClass, LocalId: number): number
    const ReplicationId = Caster.__Player_Assigned:GetAttribute('ReplicationId') :: number

    return ReplicationId * KNIGHT_ID_OFFSET + LocalId
end

local function FindKnightTarget(Caster: AgentTypes.ServerAgentClass, Turret: any)
    if not Caster:IsAlive() then
        return nil
    end

    const Target = Controller:GetTarget(Caster)
    if Target and Turret:IsInRange(Target) then
        return Target
    end

    const _, Nearest = EnemyLibrary:GetNearestEnemy(Turret:GetPivot().Position, KnightData.Range)

    return Nearest
end

local function KnightFire(Caster: AgentTypes.ServerAgentClass, Knight: Knight, Target: AbilityTypes.ServerEnemy)
    const HitData = Controller:ApplyStrategy(Caster, KnightData.Hit)

    KnightAbility:Hit(Caster, Target, HitData)

    Replicator:Effect("Lelouch_KShoot", {Knight.Id, GameEnum.Afflictions[HitData.Affliction], Target:GetId()}, true)
end

-- // Target

function Controller:IsValidTarget(Target: any): boolean
    return tostring(Target) == 'EnemyClass' and Target:IsAlive() and EnemyLibrary:GetEnemy(Target:GetId()) == Target
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

-- // Strategy

function Controller:GetStrategyElement(Caster: AgentTypes.ServerAgentClass): string?
    local Element = nil

    const ReplicationId = Caster.__Player_Assigned:GetAttribute('ReplicationId')
    for _, Agent in AgentLibrary:GetAll(ReplicationId) do
        if Agent == Caster then
            continue
        end

        const AgentData = CharacterDatabase:GetCharacterData(Agent.Name)
        if AgentData.Role ~= 'Affliction' then
            continue
        end

        if Agent:IsActive() then
            return AgentData.Element
        end

        Element = Element or AgentData.Element
    end

    return Element
end

function Controller:ApplyStrategy(Caster: AgentTypes.ServerAgentClass, HitData: AbilityTypes.HitEnemyData): AbilityTypes.HitEnemyData
    const Element = Controller:GetStrategyElement(Caster)
    if Element == nil then
        return HitData
    end

    const NewData = Table.CopyDeep(HitData)
    NewData.Affliction = Element
    NewData.Forced_Affliction = true

    return NewData
end

-- // Knights

function Controller:SummonKnight(Caster: AgentTypes.ServerAgentClass, Origin: CFrame?)
    const Data = GetAgentKnights(Caster)

    if Data.IdHeap:isEmpty() then
        return nil
    end

    const LocalId = Data.IdHeap:extract()
    const At = (Origin or Caster:GetPivot()) * KNIGHT_OFFSETS[(LocalId - 1) % #KNIGHT_OFFSETS + 1]

    const Knight: Knight = {
        Id = GetNetworkId(Caster, LocalId),
        Turret = TurretClass.new(At, {
            Lifetime = KnightData.Lifetime,
            Range = KnightData.Range,
            Interval = KnightData.Interval,
        }),
    }

    Data.Knights[LocalId] = Knight
    Replicator:Effect("Lelouch_Knightmare", {Knight.Id, 1, At}, true)

    Knight.Turret.Destroyed:Connect(function()
        Data.Knights[LocalId] = nil
        Data.IdHeap:insert(LocalId)

        Replicator:Effect("Lelouch_Knightmare", {Knight.Id, 2}, true)
    end)

    Knight.Turret:Start(function(Turret)
        return FindKnightTarget(Caster, Turret)
    end, function(_, Target)
        KnightFire(Caster, Knight, Target)
    end)

    return Knight
end

function Controller:GetKnights(Caster: AgentTypes.ServerAgentClass): { [number]: Knight }
    return GetAgentKnights(Caster).Knights
end

function Controller:GetKnightCount(Caster: AgentTypes.ServerAgentClass): number
    const Data = GetAgentKnights(Caster)

    return KnightData.Max - Data.IdHeap:size()
end

function Controller:DestroyKnights(Caster: AgentTypes.ServerAgentClass)
    for _, Knight in GetAgentKnights(Caster).Knights do
        Knight.Turret:Destroy()
    end
end

export type CommandData = {
    Tag: string,
    Time: number,
}

const function GetOrInit(Caster, Target)
    const CommandsList = Controller.__Commands

    if CommandsList[Caster] == nil then
        CommandsList[Caster] = {}
    end

    if CommandsList[Caster][Target] == nil then
        CommandsList[Caster][Target] = {}
    end
    return CommandsList[Caster][Target]
end

function Controller:HasCommand(Caster: AgentTypes.ServerAgentClass, Target: AbilityTypes.ServerEnemy, DataToMatch: CommandData?)
    const TargetCommands = GetOrInit(Caster, Target);
    
    if (typeof(DataToMatch) ~= "table" or typeof(DataToMatch.Tag) ~= 'string') and #TargetCommands > 0 then
        return true;
    end
    
    for _, Item in TargetCommands do
        if Item.Tag == DataToMatch.Tag then
            return true;
        end
    end

    return false;
end

function Controller:ApplyCommand(Caster: AgentTypes.ServerAgentClass, Target: AbilityTypes.ServerEnemy, Data: CommandData)
    const TargetCommands = GetOrInit(Caster, Target);
    const Id = #TargetCommands + 1;

    table.insert(TargetCommands, Data);

    if Data.Time then
        task.delay(Data.Time, table.remove, TargetCommands, Id)
    end

    Target:AddEffect(Data)
end

return Controller
