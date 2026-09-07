--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Libraries = ServerStorage.Modules.Libraries

local Map = require(ServerStorage.Modules.Libraries.Map)
local StagesDatabase = require(Shared.Database.Stages)
local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)
local Agents = require(Libraries.Agents)

--
local Service = {
    __Logs = {},
    __Chatting_With = {},
    __Stage = '',
    __Act = '',

    --[[
        Markers resolved for this run, set by MatchService.

        Dialogue used to be read straight out of the stage database, which a mission
        authored at runtime has no entry in. The run's own markers are the source now, and
        the stage act is only the fallback.
    ]]
    __Markers = nil :: {[string]: any}?,
}

function Service:Init()
    Network.new("NPCInteraction", "Event")
    Network:On("NPCInteraction", function(Player: Player, Type: number, Data: {Name: string, Id: number?})
        local UserId = Player:GetAttribute("ReplicationId") :: number

        Data = Data or {Name = "NPCDefaultName"}

        if GameEnum.NPCInteractions.Talk == Type then
            if Service.__Chatting_With[Player] then
                -- Network:Fire("NPCInteraction") somehow here need to cancel. If accidentally talking to one already

                return
            end

            Service.__Chatting_With[Player] = Data.Name or 'NPCDefaultName'

            for _, Agents in Agents:GetAll(UserId) do
                Agents:AddTag("TalkingToNPC")
            end
        elseif GameEnum.NPCInteractions.End == Type then
            Service.__Chatting_With[Player] = nil

            for _, Agents in Agents:GetAll(UserId) do
                Agents:RemoveTag("TalkingToNPC")
            end
        elseif GameEnum.NPCInteractions.Event == Type then
            Service:HandleEvent(Data.Name, Data.Id :: number)
        end
    end)
end

function Service:SetupNPCS(Data: {})
    for _, NPCObject in Data do
        local BufferObj = buffer.create(1)
        buffer.writeu8(BufferObj, 0, GameEnum.Replication.CreateNPC)

        Network:FireForAll("ReliableReplication", BufferObj, NPCObject)
    end
end

--- Markers for this run, falling back to the stage act for hand-built maps.
function Service:GetMarkers(): {[string]: any}
    if Service.__Markers then
        return Service.__Markers
    end

    local ActData = StagesDatabase:GetAct(Service.__Stage, Service.__Act)

    return (ActData and ActData.Markers) or {}
end

function Service:SetMarkers(Markers: {[string]: any}?)
    Service.__Markers = Markers
end

function Service:HandleEvent(NPCName: string, Id: number)
    local NPCData = Service:GetMarkers()[NPCName]

    if NPCData and NPCData.Dialogue then
        local DialogueIndexData = NPCData.Dialogue[Id]
        if not DialogueIndexData then
            return
        end

        if not Service.__Logs[NPCName] then
            Service.__Logs[NPCName] = {}
        end

        if Service.__Logs[NPCName][Id] then return end

        Service.__Logs[NPCName][Id] = true

        local TriggerData = DialogueIndexData.Enables.Trigger
        if DialogueIndexData.Enables and TriggerData then
            Map:CreateTriggerFromData(TriggerData)
        end
    end
end

return Service