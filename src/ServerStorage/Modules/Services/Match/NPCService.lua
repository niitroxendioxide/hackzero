--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)
local Agents = require(ServerStorage.Modules.Libraries.Agents)

--
local Service = {
    __Chatting_With = {}
}

function Service:Init()
    Network.new("NPCInteraction", "Event")
    Network:On("NPCInteraction", function(Player: Player, Type: number, Data: {Name: string})
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
        elseif GameEnum.NPCInteractions.End then
            Service.__Chatting_With[Player] = nil

            for _, Agents in Agents:GetAll(UserId) do
                Agents:RemoveTag("TalkingToNPC")
            end
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

return Service