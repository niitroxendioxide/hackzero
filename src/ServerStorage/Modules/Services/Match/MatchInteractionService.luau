---
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")


const Services = ServerStorage.Modules.Services;
const Shared = ReplicatedStorage.Modules.Shared;

const LootService = require(Services.Match.LootService);

const Signal = require(Shared.Utility.Signal);
const Network = require(Shared.Network);
const GameEnum = require(Shared.GameEnum);
const Debugger = require(Shared.Utility.Debugger);

--- type
type InteractionObject = {
    Id: number,
    TriggerCount: number,
    Triggered: boolean,
    Type: string,
    Collider: BasePart,
    Core: { [string]: any },
}

--- definitions
const EVENT_NAME = "MatchInteraction"
const MAX = 2 ^ 16;
const Service = {
    ids = 0,
    objects = {} :: {InteractionObject},
    triggered = Signal.new() :: Signal.ScriptSignal<number, { [string]: any, SetValues: { [string]: any } }>,
}

-- Privates
const function IdType(Type: string) : number
    return GameEnum.MatchInteractionType[Type]
end

const function NewObject(Data: { Type: string, Collider: BasePart, }): InteractionObject 
    Service.ids += 1;

    return {
            Id = Service.ids;
            TriggerCount = 0,
            Triggered = false,
            Type = Data.Type,
            Collider = Data.Collider,
            Core = Data,

        } :: InteractionObject

end

const function CompressObject(Object: InteractionObject): {buffer | BasePart}
    local Created = buffer.create(6)

    buffer.writeu16(Created, 0, Object.Id)
    buffer.writeu16(Created, 2, Object.TriggerCount)
    buffer.writeu8(Created, 4, Object.Triggered == true and 1 or 0)
    buffer.writeu8(Created, 5, IdType(Object.Type))

    return {Created, Object.Collider};
end

const function GetObject(id: number): InteractionObject?
    for _, Obj in Service.objects do
        if Obj.Id == id then
            return Obj
        end
    end

    return;
end

-- Publics
type CreationData = { Type: string, Collider: BasePart, [string]: any }

function Service:Init()

    Network.new(EVENT_NAME, 'Event');
    Network:On(EVENT_NAME, function(Player: Player, Type: number, ...)
        const Args = {...}

        if Type == GameEnum.MatchInteraction.Triggered then
            const TriggeredObjectId = Args[1] :: number
            Service:Trigger(TriggeredObjectId, Player)    
        end
    end)

end

function Service:Trigger(Id: number, Player: Player)
    const Object = GetObject(Id)
    if Object == nil then
        Debugger:DebugLine("MatchInteractionService::Trigger", `Object given is nil, didn't find id: {Id}`, 10)

        return;
    end

    if typeof(Object.Core.Drops) == 'table' then
        LootService:GiveLootToPlayer(Player, Object.Core.Drops, true)
    end

    Service.triggered:Fire(Id, Object.Core)
end

function Service:AddInteraction(Data: CreationData, __no_trigger: boolean): boolean
    if (Service.ids >= MAX) then
        Debugger:WarnLine("MatchInteractionService::AddInteraction", "Couldnt add another interaction object, reason: (NOT ENOUGH SPACE)", 10);

        return;
    end

    local Object = NewObject(Data)

    if not __no_trigger then
        Network:FireForAll(EVENT_NAME, GameEnum.MatchInteraction.Create, CompressObject(Object))
    end

    table.insert(Service.objects, Object)

    return Object
end

function Service:BatchAddInteraction(DataList: { CreationData } )
    
    local Added = {}
    for _, Int in DataList do
        local Result = Service:AddInteraction(Int, true)
        if (Result == nil) then
            Debugger:DebugLine("MatchInteractionService::BatchAddInteraction", "Limit reached, cutting off.", 100)

            break
        end

        table.insert(Added, CompressObject(Result))
    end

    Network:FireForAll(EVENT_NAME, GameEnum.MatchInteraction.BatchCreate, Added)

end

return Service