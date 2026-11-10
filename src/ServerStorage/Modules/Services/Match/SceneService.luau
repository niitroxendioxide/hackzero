--[[
    @class SceneService

    Pre-fight scenes: models a mission event places around its trigger, posed in an
    animation, before anyone walks in (Saiyans cornering Namekians, say). They only exist on
    the clients (`Client/Libraries/Scenes`), the server just keeps track of the slots.

    An event declares them in its config:

    ```lua
    Scene = {
        {Type = 'Model', Src = 'Characters.Enemies.Saiyan', Animation = 'Missions.Namek.SaiyanThreat', At = CFrame.new(0, 0, -6), Enemy = 'Saiyan'},
        {Type = 'Model', Src = 'Characters.Recruits.Namekian', Animation = 'Missions.Namek.NamekianBeg1', At = CFrame.new(2, 0, 4), Ally = 'Namekian'},
        {Type = 'Effect', Src = 'VFX.Namek.Smoke', At = CFrame.new(0, 0, 0)},
    },
    ```

    `Src` is a path under ReplicatedStorage.Assets to a Model (posed with `Animation`) or a
    BasePart (an effect: put particles, lights or sounds inside it). `Type` is only a label.

    `At` is relative to the event's trigger part. A slot with `Enemy`/`Ally` is handed to the
    first enemy/ally of that kind the event spawns (`Claim`): it spawns where the slot stands,
    and the client turns the posed model into it instead of making a new one. Slots nobody
    links to are scenery, cleared the moment the event starts; linked slots nobody claimed
    are cleared once it ends. The scene only ever plays once, before the first time the
    trigger fires.
]]
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Shared = ReplicatedStorage.Modules.Shared

const GameEnum = require(Shared.GameEnum)
const Network = require(Shared.Network)

const CHANNEL = 'Entities'

export type SceneEntry = {
    Type: string,
    Src: string,
    Animation: string?,
    At: CFrame?,
    Enemy: string?,
    Ally: string?,
}

--- What enemies/recruits carry to find their model on the client.
export type SceneLink = {Event: string, Slot: number}

type Slot = {
    Slot: number,
    Entry: SceneEntry,
    CFrame: CFrame,
    Claimed: boolean,
    Cleared: boolean,
}

const Service = {
    __Slots = {} :: {[string]: {Slot}},
}

--
local function Send(Action: number, Target: Player?, ...: any)
    const Object = buffer.create(1)
    buffer.writeu8(Object, 0, Action)

    if Target then
        Network:Fire(CHANNEL, Target, Object, ...)
    else
        Network:FireForAll(CHANNEL, Object, ...)
    end
end

local function GetTrigger(Name: string): BasePart?
    const Map = workspace.World:FindFirstChild("Map")
    const Triggers = Map and Map:FindFirstChild("Triggers")

    return if Triggers then Triggers:FindFirstChild(Name) :: BasePart? else nil
end

local function Pack(Event: string): {{Slot: number, Src: string, Animation: string?, CFrame: CFrame}}
    const Packed = {}

    for _, Slot in Service.__Slots[Event] or {} do
        if not Slot.Claimed and not Slot.Cleared then
            table.insert(Packed, {Slot = Slot.Slot, 
            Src = Slot.Entry.Src, Animation = Slot.Entry.Animation, CFrame = Slot.CFrame,
            Type = GameEnum.SceneItemType[Slot.Entry.Type],
        })
        end
    end

    return Packed
end

local function Clear(Event: string, All: boolean)
    const Cleared = {}

    for _, Slot in Service.__Slots[Event] or {} do
        const Linked = Slot.Entry.Enemy ~= nil or Slot.Entry.Ally ~= nil

        if not Slot.Claimed and not Slot.Cleared and (All or not Linked) then
            Slot.Cleared = true
            table.insert(Cleared, Slot.Slot)
        end
    end

    if #Cleared > 0 then
        Send(GameEnum.EntityReplication.ClearScene, nil, Event, Cleared)
    end
end

-- # Publics

--- Read every event's `Scene` and put them up for everyone. MatchService calls it before the mission begins.
function Service:Bind(Mission: any)
    table.clear(Service.__Slots)

    for Event, Data in Mission:GetGuide() do
        if typeof(Data) ~= 'table' or typeof(Data.Scene) ~= 'table' then
            continue
        end

        const Trigger = GetTrigger(Event)
        if not Trigger then
            warn(`SceneService: event "{Event}" has a Scene but no trigger part to place it around.`)

            continue
        end

        const Slots = {}
        for Index, Entry in Data.Scene :: {SceneEntry} do
            table.insert(Slots, {
                Slot = Index,
                Entry = Entry,
                CFrame = Trigger:GetPivot() * (Entry.At or CFrame.identity),
                Claimed = false,
                Cleared = false,
            })
        end

        Service.__Slots[Event] = Slots
        Send(GameEnum.EntityReplication.SetScene, nil, Event, Pack(Event))
    end

    --- Enemies of the first wave claim their slots inside Start, before this fires.
    Mission.EventStarted:Connect(function(Event: string, EventObject: any)
        if not Service.__Slots[Event] then
            return
        end

        Clear(Event, false)

        EventObject.Finished:Once(function()
            Clear(Event, true)
        end)
    end)
end

--[[
    Hand the first free slot of `Event` linked to `Name` to whoever is spawning.

    @param Kind 'Enemy' or 'Ally', which field of the entry `Name` is matched against.
    @return The link to give the entity, and where it should stand. Nil when no slot is free.
]]
function Service:Claim(Event: string, Kind: 'Enemy' | 'Ally', Name: string): (SceneLink?, CFrame?)
    for _, Slot in Service.__Slots[Event] or {} do
        if Slot.Claimed or Slot.Cleared or (Slot.Entry :: any)[Kind] ~= Name then
            continue
        end

        Slot.Claimed = true

        return {Event = Event, Slot = Slot.Slot}, Slot.CFrame
    end

    return nil, nil
end

--- Catch a player who joined late up on every scene still standing (TeamService:Sync).
function Service:Load(Player: Player)
    for Event in Service.__Slots do
        const Packed = Pack(Event)

        if #Packed > 0 then
            Send(GameEnum.EntityReplication.SetScene, Player, Event, Packed)
        end
    end
end

return Service
