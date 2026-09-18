---
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Shared = ReplicatedStorage.Modules.Shared;

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
const GameEnum = require(Shared.GameEnum);
const Network = require(Shared.Network);

--- definitions
const EVENT_NAME = "MatchInteraction"
const MAX = 2 ^ 16;
const Service = {
    ids = 0,
    objects = {},
}

---
type InteractionObject = {
    Id: number,
    TriggerCount: number,
    Triggered: boolean,
    Type: string,
}

-- Privates
const function IdType(Type: string) : number
    return GameEnum.MatchInteractionType[Type]
end

const function NewObject(Type: string): InteractionObject 
    Service.ids += 1;

    return {
            Id = Service.ids;
            TriggerCount = 0,
            Triggered = false,
            Type = Type,

        } :: InteractionObject

end

const function ObjectToBuffer(Object: InteractionObject)
    local Created = buffer.create(6)

    buffer.writeu16(Created, 0, Object.Id)
    buffer.writeu16(Created, 2, Object.TriggerCount)
    buffer.writeu8(Created, 4, Object.Triggered == true and 1 or 0)
    buffer.writeu8(Created, 5, IdType(Object.Type))

    return Created
end

-- Publics

function Service:Init()

    Network.new(EVENT_NAME, 'Event');
    Network:On(EVENT_NAME, function(Player: Player, Type: number, ...)
        
        if Type == GameEnum.MatchInteraction.Triggered then
            
        end

    end)

end

function Service:AddInteraction(Data: { any }, __no_trigger: boolean): boolean
    if (Service.ids >= MAX) then
        Debugger:WarnLine("MatchInteractionService::AddInteraction", "Couldnt add another interaction object, reason: (NOT ENOUGH SPACE)", 10);

        return;
    end

    local Object = NewObject (Data.Type)

    if not __no_trigger then
        Network:FireForAll(EVENT_NAME, GameEnum.MatchInteraction.Create, ObjectToBuffer(Object))
    end

    table.insert(Service.objects, Object)

    return Object
end

function Service:BatchAddInteraction(DataList: { { any } } )
    
    local Added = {}
    for _, Int in DataList do
        local Result = Service:AddInteraction(Int, true)
        if (Result == nil) then
            Debugger:DebugLine("MatchInteractionService::BatchAddInteraction", "Limit reached, cutting off.", 100)

            break
        end

        table.insert(Added, ObjectToBuffer(Result))
    end

    Network:FireForAll(EVENT_NAME, GameEnum.MatchInteraction.BatchCreate, Added)

end

return Service