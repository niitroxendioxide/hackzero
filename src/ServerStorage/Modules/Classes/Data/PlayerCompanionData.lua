local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Companions = require(Shared.Database.Companions)
local CompanionTraits = require(Shared.Database.CompanionTraits)

local Types = require(Shared.Types.Companions)
local Rng = Random.new()

--[[
    Roll for a stat using a numberrange

    @return Tier (The tier of the stat rolled, common, epic, legendary, mythical, etc.)
    @return Value the value of the stat rolled
]]
local function RollForStat(Range: NumberRange, Invert: boolean): (number, number)
    local Chance = Rng:NextNumber(0, 100)
    local Value = 0
    local Tier = 'Common'
    local Start, Goal = Range.Min, Range.Max
    if Invert then
        Goal, Start = Start, Goal
    end

    if Chance < 0.5 then
        Tier = 'Mythical'
    elseif Chance < 7.5 then
        Tier = 'Legendary'
    elseif Chance < 38 then
        Tier = 'Epic'
    end

    local MultRange = Statics.Stat_Tier_Mults[Tier]
    local Percent = Rng:NextNumber(MultRange[1], MultRange[2])

    Value = math.lerp(Start, Goal, Percent)

    return Value, GameEnum.Tiers[Tier]
end

--
local CompanionDataClass = {}
CompanionDataClass.__index = CompanionDataClass

function CompanionDataClass.new(Name: string, Data: {[string]: any}): Types.PlayerCompanionDataClass
    local self = setmetatable({}, CompanionDataClass)
    self.__Id = Data.Id
    self.__Name = Name
    self.__Level = Data.Level or 1
    self.__Experience = Data.Experience or 0
    self.__Base_Stats = Data.BaseStats or {}
    self.__Level_Stats = Data.LevelStats or {}
    self.__Obtainment_Date = Data.ObtainmentDate or DateTime.now().UnixTimestamp
    self.__Stats_Rarity = Data.StatsRarity
    self.__Trait = Data.Trait or 'None'


    return self
end

function CompanionDataClass.randomize(Name: string): Types.PlayerCompanionDataClass
    local BaseStats = {}
    local LevelStats = {}
    local StatRarities = {Level = {}, Base = {}}

    for StatName, StatValue: number | NumberRange in Companions:GetStats(Name) do
        if typeof(StatValue) == 'number' then
            BaseStats[StatName] = StatValue
        else
            local Value, Rarity = RollForStat(StatValue, StatName == 'AttackRate' or StatName == 'AttackSpeed')

            StatRarities.Base[StatName] = Rarity
            BaseStats[StatName] = Value
        end
    end

    for StatName, StatValue: number | NumberRange in Companions:GetLevelStats(Name) do
        if typeof(StatValue) == 'number' then
            LevelStats[StatName] = StatValue
        else
            local Value, Rarity = RollForStat(StatValue, StatName == 'AttackRate' or StatName == 'AttackSpeed')

            StatRarities.Level[StatName] = Rarity
            LevelStats[StatName] = Value
        end
    end

    local Percent = Rng:NextNumber(0, 100)
    local Trait = 'None'

    if Percent < 0.5 then
        local Mythical = CompanionTraits:GetAllOfRarity("Mythical")

        Trait = Mythical[Rng:NextInteger(1, #Mythical)]
    elseif Percent < 5 then
        local Legendary = CompanionTraits:GetAllOfRarity("Legendary")

        Trait = Legendary[Rng:NextInteger(1, #Legendary)]
    elseif Percent < 20 then
        local Epic = CompanionTraits:GetAllOfRarity("Epic")

        Trait = Epic[Rng:NextInteger(1, #Epic)]
    end

    return CompanionDataClass.new(Name, {
        Level = 1,
        Id = HttpService:GenerateGUID(false),
        BaseStats = BaseStats,
        LevelStats = LevelStats,
        ObtainmentDate = DateTime.now().UnixTimestamp,
        StatsRarity = StatRarities,
        Trait = Trait
    })
end

function CompanionDataClass:GetStats()
    local Stats = {}

    for StatName, StatValue in self.__Base_Stats do
        local LevelValue = self.__Level_Stats[StatName] or 0

        Stats[StatName] = StatValue + (LevelValue*self.__Level)
    end

    return Stats
end

function CompanionDataClass:SetLevel(Level: number)
    self.__Level = Level
end

function CompanionDataClass:Compress()
    local DataBuffer = buffer.create(12)
    buffer.writeu8(DataBuffer, 0, Companions:GetIdFor(self.__Name))
    buffer.writeu8(DataBuffer, 1, self.__Level)
    buffer.writeu8(DataBuffer, 2, CompanionTraits:GetIdFor(self.__Trait))

    local Stats = self:GetStats()
    buffer.writeu16(DataBuffer, 3, Stats.Attack)
    buffer.writeu16(DataBuffer, 5, Stats.Defense)
    buffer.writeu16(DataBuffer, 7, Stats.Speed * 100)

    buffer.writeu16(DataBuffer, 9, Stats.AttackSpeed * 100)
    buffer.writeu8(DataBuffer, 11, (Stats.AttackRate * 10))

    return DataBuffer
end

function CompanionDataClass:ToData()
    return {
        Id = self.__Id,
        Level = self.__Level,
        Trait = self.__Trait,
        BaseStats = self.__Base_Stats,
        Experience = self.__Experience,
        LevelStats = self.__Level_Stats,
        ObtainmentDate = self.__Obtainment_Date,
        StatsRarity = self.__Stats_Rarity
    }
end

return CompanionDataClass
