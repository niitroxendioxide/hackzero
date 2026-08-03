---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local Heap = require(ReplicatedStorage.Modules.Shared.Utility.Heap)
local AgentTypes = require(Shared.Types.Agents)
local AbilityTypes = require(Shared.Types.Abilities)


---
const HITS_NEEDED = 3
const DEFAULT_VANISH_TIME = 30

---
const Controller = {
    __Cache = {},
    __Agent_Fishes = {} :: { [AgentTypes.ServerAgentClass]: { IdHeap: Heap.Heap, Fishes: {}, Hits: number } },
}

function Controller:AddUltimateCharge(Caster: AgentTypes.ServerAgentClass, Amount: number, Maximum: number)
    if (Controller.__Cache[Caster] == nil) then
        Controller.__Cache[Caster] = 0
    end

    --
    Caster:UpdateMeter('AkaCharge', Amount)
    Controller.__Cache[Caster] = math.clamp(Controller.__Cache[Caster] + Amount, 0, Maximum)
    
end

function Controller:MarkSpecialHit(Caster: AgentTypes.ServerAgentClass, Target: AbilityTypes.ServerEnemy, Limit: number)
    if not Controller.__Agent_Fishes[Caster] then
        Controller.__Agent_Fishes[Caster] = {
            LimitSet = Limit,
            IdHeap = Heap.new(Limit),
            Hits = 0,
            Fishes = {},
        }
    end

    local Data = Controller.__Agent_Fishes[Caster]
    local IsEmpty = Data.IdHeap:isEmpty()
    if IsEmpty then
        return
    end

    local Compared = HITS_NEEDED - 1;
    if Data.Hits < Compared then
        Data.Hits += 1;
    elseif Data.Hits >= Compared then
        Data.Hits = 0;

        local X, Z = math.random(-90, 90) / 10, math.random(60, 130) / 10
        local NewId = Data.IdHeap:extract()
        Data.Fishes[NewId] = {
            At = (Caster:GetPivot() * CFrame.new(X, math.random(-5, 55) / 10, Z)).Position ,
            Thread = nil,
        }

        Replicator:Effect("Chihiro_FishKuro", {Caster, NewId, 'Create', Data.Fishes[NewId].At}, true)

        Data.Fishes[NewId].Thread = task.delay(DEFAULT_VANISH_TIME, function()
            Replicator:Effect("Chihiro_FishKuro", {Caster, NewId, 'Cleanup'}, true)

            Data.Fishes[NewId] = nil
            Data.IdHeap:insert(NewId)
        end)
    end
end

function Controller:CashOutFishes(Caster: AgentTypes.ServerAgentClass, Target: AbilityTypes.ServerEnemy, Handler: () -> ())
    local CasterData = Controller.__Agent_Fishes[Caster]
    if not CasterData then
        return;
    end

    local At = 0;
    for Id, Fish in CasterData.Fishes do
        if Fish.Thread ~= coroutine.running() then
            task.cancel(Fish.Thread)
        end

        CasterData.IdHeap:insert(Id)
        
        ---
        task.delay(At * 0.15, function()
            local Direction = CFrame.lookAt(Fish.At, Target:GetPivot().Position).LookVector
            Replicator:Effect("Chihiro_FishKuro", {Caster, Id, 'Shoot', Direction}, true)

            Handler(Fish.At, Direction)
        end)

        At += 1;
    end

    CasterData.Fishes = {}
end

function Controller:UseUltimateCharge(Caster: AgentTypes.ServerAgentClass): number
    local StoredAmount = Controller.__Cache[Caster]
    Caster:UpdateMeter('AkaCharge', -StoredAmount)

    Controller.__Cache[Caster] = 0

    return StoredAmount
end

return Controller