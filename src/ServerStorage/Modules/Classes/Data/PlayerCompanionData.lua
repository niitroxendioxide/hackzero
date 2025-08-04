local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Companions = require(Shared.Database.Companions)
local CompanionTraits = require(Shared.Database.CompanionTraits)

local Rng = Random.new()

--
local CompanionDataClass = {}
CompanionDataClass.__index = CompanionDataClass

function CompanionDataClass.new(Name: string, Data: {[string]: any})
    local self = setmetatable({}, CompanionDataClass)
    self.__Id = Data.Id
    self.__Name = Name
    self.__Level = Data.Level or 1
    self.__Experience = Data.Experience or 0
    self.__Base_Stats = Data.BaseStats or {}
    self.__Level_Stats = Data.LevelStats or {}
    self.__Obtainment_Date = Data.ObtainmentDate or DateTime.now().UnixTimestamp
    self.__Trait = Data.Trait or 'None'


    return self
end

function CompanionDataClass.randomize(Name: string)
    local BaseStats = {}
    local LevelStats = {}

    for StatName, StatValue: number | NumberRange in Companions:GetStats(Name) do
        if typeof(StatValue) == 'number' then
            BaseStats[StatName] = StatValue
        else
            local Chosen = Rng:NextNumber(StatValue.Min, StatValue.Max)
            local Percent = (Chosen - StatValue.Min) / (StatValue.Max - StatValue.Min)

            print(StatName, "got a: ", Percent)

            BaseStats[StatName] = Chosen
        end
    end

    for StatName, StatValue: number | NumberRange in Companions:GetLevelStats(Name) do
        if typeof(StatValue) == 'number' then
            LevelStats[StatName] = StatValue
        else
            LevelStats[StatName] = Rng:NextNumber(StatValue.Min, StatValue.Max)
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
        local Rare = CompanionTraits:GetAllOfRarity("Rare")

        Trait = Rare[Rng:NextInteger(1, #Rare)]
    end

    return CompanionDataClass.new(Name, {
        Level = 1,
        BaseStats = BaseStats,
        LevelStats = LevelStats,
        ObtainmentDate = DateTime.now().UnixTimestamp,
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
        Level = self.__Level,
        Trait = self.__Trait,
        BaseStats = self.__Base_Stats,
        Experience = self.__Experience,
        LevelStats = self.__Level_Stats,
        ObtainmentDate = self.__Obtainment_Date,
    }
end

return CompanionDataClass
