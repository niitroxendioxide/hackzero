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
    self.__Player_Object = Player
    self.__Designated_Id = 0
    self.__Team = Team

    return self
end

function PlayerClass.GetId(self: Types.StagePlayer)
    return self.__Designated_Id
end

function PlayerClass.GetTeam(self: Types.StagePlayer)
    return self.__Team
end

function PlayerClass.GetBase(self: Types.StagePlayer)
    return self.__Player_Object
end

return PlayerClass
