--[[
    @class MissionPacket

    Builds the packet that describes one run, and is the only place that needs to know its
    shape. The lobby fills one in, `TeleportService` puts it on the teleport payload, and
    `MatchService` unpacks it on the other side.

    A packet does not have to point at a mission that exists anywhere. A runtime-authored
    mission carries its own seed, its own room budget and its own kind, and the match server
    builds the rest from those.

    ## Where this gets used

    From whatever lobby service owns the mission NPC:

    ```lua
    local MissionPacket = require(Shared.Libraries.MissionPacket)

    local Packet = MissionPacket.Procedural({
        Kind  = 'Recover',                     -- picks Components/Missions/Recover
        Stage = 'DungeonEx',                   -- which map asset / room prefabs to build from
        Act   = 'Intro',
        Rooms = 8,
        Extent = 25,

        Display_Name = "Recover my suitcase!",
        Recommended_Level = 5,

        Data = { Target_Item = 'Suitcase' },   -- anything the world handler wants to read
    })

    MissionPacket.Apply(Party, Packet)         -- SetData + SwitchStage, in the right order
    ```

    The seed is minted here, not at match time, so the NPC can decide the kind and the goal
    off the same number the map will be built from, and show it to the player.

    ## Kinds

    `Kind` is the classification, and the only one the match server needs: it resolves to
    `Components/Missions/<Kind>`, whose `OnBuild` authors the mission into the generated
    rooms. Everything else about the mission is yours to put in `Data`.
]]

local MAX_SEED = 2 ^ 31 - 1

local MissionPacket = {}

export type ProceduralConfig = {
    --- Mission kind, resolves to `Components/Missions/<Kind>` on the match server.
    Kind: string,

    --- Stage supplying the map asset and room prefabs.
    Stage: string,
    Act: string?,

    --- 0 or nil mints one here, so the lobby knows it before the match starts.
    Seed: (number | string)?,

    --- How many rooms the layout should have, halls excluded.
    Rooms: number?,
    --- Hard cap on total tiles. Defaults to twice the room count.
    Extent: number?,
    --- Room prefab folder under the stage's map asset.
    Source: string?,

    Display_Name: string?,
    Description: string?,
    Recommended_Level: number?,
    Difficulty: string?,

    --- Anything the world handler should read. Merged into the packet.
    Data: {[string]: any}?,

    --[[
        A complete mission definition, if you already have one and only want the map
        generated. Same shape as a database entry: Markers / Triggers / Destructibles /
        Completion. Leave it out and the world handler authors everything.
    ]]
    Mission: {[string]: any}?,
}

export type Packet = {
    Stage: string,
    Act: string?,
    Kind: string?,

    Seed: number,
    Procedural: boolean,
    Generation: {[string]: any}?,

    Display_Name: string?,
    Description: string?,
    Recommended_Level: number?,
    Difficulty: string?,

    Mission: {[string]: any}?,
    MissionId: string?,

    [string]: any,
}

--- Fold a string seed down to the integer the generator wants, same rule the match uses.
local function ToSeedNumber(Value: (string | number)?): number
    if typeof(Value) == 'number' then
        return math.floor(math.abs(Value)) % MAX_SEED
    end

    if typeof(Value) ~= 'string' or #Value < 1 then
        return 0
    end

    local Hash = 2166136261 % MAX_SEED
    for Index = 1, #Value do
        Hash = (Hash * 31 + string.byte(Value, Index)) % MAX_SEED
    end

    return Hash
end

--- A fresh seed. Mint one per mission the NPC offers, and keep it, it names the run.
function MissionPacket.NewSeed(): number
    return Random.new():NextInteger(1, MAX_SEED)
end

--[[
    A `Random` derived from a seed, so the lobby can roll the kind, the goal and the
    flavour off the same number the map will be built from and have it all line up.

    @param p_Salt Offsets the stream, use a different one per independent decision.
]]
function MissionPacket.RandomFor(p_Seed: (number | string), p_Salt: number?): Random
    return Random.new(ToSeedNumber(p_Seed) + (p_Salt or 0))
end

--[[
    Build a packet for a procedurally generated mission that exists nowhere but in this
    packet.

    @param p_Config See `ProceduralConfig`.

    @return The packet, ready for `MissionPacket.Apply`.
]]
function MissionPacket.Procedural(p_Config: ProceduralConfig): Packet
    local Seed = ToSeedNumber(p_Config.Seed)
    if Seed <= 0 then
        Seed = MissionPacket.NewSeed()
    end

    local Rooms = p_Config.Rooms
    local Packet: Packet = {
        Stage = p_Config.Stage,
        Act = p_Config.Act,
        Kind = p_Config.Kind,

        Seed = Seed,
        Procedural = true,
        Generation = {
            Seed = Seed,
            Rooms = Rooms,
            Extent = p_Config.Extent or (Rooms and Rooms * 2 or nil),
            Source = p_Config.Source,
        },

        Display_Name = p_Config.Display_Name,
        Description = p_Config.Description,
        Recommended_Level = p_Config.Recommended_Level,
        Difficulty = p_Config.Difficulty or 'EASY',

        Mission = p_Config.Mission,
    }

    --- Whatever the handler needs, carried alongside rather than nested, so it reads as
    --- `Builder:GetData().Target_Item` on the other side.
    for Key, Value in (p_Config.Data or {}) do
        if Packet[Key] == nil then
            Packet[Key] = Value
        end
    end

    return Packet
end

--[[
    Build a packet for a mission that already exists in the database.
    This is the pre-generated path, unchanged, kept here so both live in one place.
]]
function MissionPacket.FromDatabase(p_Mission_Id: string, p_Stage: string, p_Act: string, p_Extra: {[string]: any}?): Packet
    local Packet: Packet = {
        Stage = p_Stage,
        Act = p_Act,

        Seed = 0,
        Procedural = false,

        MissionId = p_Mission_Id,
        Difficulty = 'EASY',
    }

    for Key, Value in (p_Extra or {}) do
        Packet[Key] = Value
    end

    return Packet
end

--[[
    Check a packet before it is sent. Cheap sanity, not a security boundary.

    @return Whether it is well formed, and what is wrong when it is not.
]]
function MissionPacket.Validate(p_Packet: Packet): (boolean, string?)
    if typeof(p_Packet) ~= 'table' then
        return false, "Packet is not a table"
    end

    if typeof(p_Packet.Stage) ~= 'string' or #p_Packet.Stage < 1 then
        return false, "Packet has no Stage, the map asset and room prefabs come from it"
    end

    if p_Packet.Procedural then
        if typeof(p_Packet.Seed) ~= 'number' or p_Packet.Seed <= 0 then
            return false, "Procedural packet needs a concrete Seed, mint one with MissionPacket.NewSeed()"
        end

        if p_Packet.Kind == nil and p_Packet.Mission == nil then
            return false, "Procedural packet needs either a Kind (so a world handler can author it) or an inline Mission"
        end
    elseif p_Packet.MissionId == nil and p_Packet.Mission == nil then
        return false, "Non-procedural packet needs a MissionId or an inline Mission"
    end

    return true
end

--[[
    Put the packet on a party, in the order the two calls have to happen.

    @param p_Party The party class.
    @param p_Packet The packet.
    @param p_Type Mission type, defaults to 'Mission'.

    @return Whether it applied, and why not when it did not.
]]
function MissionPacket.Apply(p_Party: any, p_Packet: Packet, p_Type: string?): (boolean, string?)
    local Valid, Message = MissionPacket.Validate(p_Packet)
    if not Valid then
        return false, Message
    end

    p_Party:SetData(p_Packet)
    p_Party:SwitchStage(p_Type or 'Mission', p_Packet.Stage, p_Packet.Act)

    return true
end

return MissionPacket
