--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)

--
local PlayersLibrary = {
    __Cache = {},
    __Count = 0,
}

function PlayersLibrary:Add(Player: Player, Class: Types.StagePlayer)
    PlayersLibrary.__Count += 1

    Class.__Designated_Id = PlayersLibrary.__Count

    PlayersLibrary.__Cache[Player] = Class
end

function PlayersLibrary:Remove(Player: Player)
    PlayersLibrary.__Cache[Player] = nil
end

function PlayersLibrary:Get(Player: Player): Types.StagePlayer
    return PlayersLibrary.__Cache[Player]
end

function PlayersLibrary:GetFromPart(BasePart: BasePart): Types.StagePlayer?
    local Character = BasePart:FindFirstAncestorOfClass("Model")
    local PlayerFromCharacter = Players:GetPlayerFromCharacter(Character)

    if PlayerFromCharacter then
        return PlayersLibrary:Get(PlayerFromCharacter)
    end

    return nil
end

function PlayersLibrary:GetFromAgent(Agent: AgentTypes.ServerAgentClass): Types.StagePlayer?
    for _, Player in PlayersLibrary.__Cache do
        if Player:GetBase().UserId == Agent.__User then
            return Player
        end
    end

    return
end

function PlayersLibrary:GetAll()
    local List = {}
    for _, Class in PlayersLibrary.__Cache do
        table.insert(List, Class)
    end

    return List
end

return PlayersLibrary
