--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Stages)
local AgentTypes = require(Shared.Types.Agents)

--
local PlayerClass = {}
PlayerClass.__index = PlayerClass

function PlayerClass.new(Player: Player, Team: {AgentTypes.ServerAgentClass}): Types.StagePlayer
    local self = setmetatable({}, PlayerClass)
    self.__Match_Inventory = {}
    self.__Player_Object = Player
    self.__Loot_Obtained = {}
    self.__Designated_Id = 0
    self.__Team = Team

    return self
end

function PlayerClass.GiveMatchItem(self: Types.StagePlayer)
    
end

function PlayerClass.TakeMatchItem(self: Types.StagePlayer)
    
end

function PlayerClass.AddLoot(self: Types.StagePlayer, Type: string, Data: {Amount: number, Extra: Types.LootExtraData})
    table.insert(self.__Loot_Obtained, {
        Type = Type,
        Amount = Data.Amount,
        Extra = Data.Extra
    })
end

function PlayerClass.GetObtainedLoot(self: Types.StagePlayer): {Types.LootObject}
    return self.__Loot_Obtained
end

function PlayerClass.AddModifier(self: Types.StagePlayer)
    
end

function PlayerClass.TakeModifier(self :Types.StagePlayer)
    
end

function PlayerClass.GetId(self: Types.StagePlayer): number
    return self.__Designated_Id
end

function PlayerClass.GetTeam(self: Types.StagePlayer)
    return self.__Team
end

function PlayerClass.GetBase(self: Types.StagePlayer)
    return self.__Player_Object
end

return PlayerClass
