local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared


local Types = require(Shared.Types.Companions)
local AgentTypes = require(Shared.Types.Agents)
local Companions = require(Shared.Database.Companions)

--
local StatsClass = {}
StatsClass.__index = StatsClass

function StatsClass.new(Name: string, Stats: {}, Level: number)
    local self = setmetatable({}, StatsClass)
    self.__Items = {}
    self.__Stats = Stats
    self.__Level = Level

    return self
end

function StatsClass.GetStat(self: Types.CompanionStatsClass, Name: string)
    return self.__Stats[Name] or 0
end

function StatsClass.Add(self: Types.CompanionStatsClass, GearObject: AgentTypes.GearObject)
    table.insert(self.__Items, GearObject)
end

function StatsClass.Remove(self: Types.CompanionStatsClass, GearObject: AgentTypes.GearObject)
    local index = table.find(self.__Items, GearObject)
    if index then
        table.remove(self.__Items, index)
    end
end

return StatsClass
