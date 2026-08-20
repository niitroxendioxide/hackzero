--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local ArtifactDatabase = require(Database.Artifacts)
local CharacterDatabase = require(Database.Characters)
--local ArtifactDatabase = require(Database.Artifacts)

const ArtifactStats = require(Database.ArtifactStats)
const SlotStats = {
    'Health',
    'Attack',
    'Defense'
}

--
local function DecideMainStatValue(MainStat: string, ArtifactLevel: number, ArtifactTier: number)
    if ArtifactStats[MainStat] and ArtifactStats[MainStat][ArtifactTier] then
        local Min, Max = ArtifactStats[MainStat][ArtifactTier].Min, ArtifactStats[MainStat][ArtifactTier].Max;

        return math.lerp(Min, Max, ArtifactLevel / 99)
    end

    return 0
end

local function RandomizeRarity()
    local Rarities = Statics.Artifact_Rarities;
    local Number = Random.new():NextNumber(0, 100);

    if Number < Rarities.Mythical then
        return 'Mythical'
    elseif Number < Rarities.Legendary then
        return 'Legendary'
    elseif Number < Rarities.Epic then
        return 'Epic'
    end

    return 'Rare'
end

--
local PlayerArtifactDataClass = {}
PlayerArtifactDataClass.__index = PlayerArtifactDataClass;

function PlayerArtifactDataClass.new(ArtifactData: Types.PlayerArtifactData, AgentEquipped: Types.PlayerAgentDataClass?): (Types.PlayerArtifactDataClass)
    local self = setmetatable({}, PlayerArtifactDataClass)

    -- Requires another parameter
    self.__Equipped = AgentEquipped

    --
    self.__Id = ArtifactData.Id
    self.__Name = ArtifactData.Name
    self.__Level = ArtifactData.Level
    self.__Stats = ArtifactData.Stats
    self.__Tier = ArtifactData.Tier
    self.__Slot = ArtifactData.Slot

    return self
end

function PlayerArtifactDataClass.randomize(Name: string, Tier: string?, Level: number, GivenSlot: number?)
    local Generator = Random.new()

    --
    Tier = Tier or RandomizeRarity()

    local Slot = GivenSlot or Generator:NextInteger(1, 6)
    local ArtifactLevel = math.clamp(math.floor(Generator:NextNumber(0.75, 1.25) * Level), 1, 99)
    local SubStatAmount = math.max((5 - GameEnum.Tiers[Tier]) - math.round(Generator:NextNumber(0, 0.6)), 1)
    local TotalBoosts = math.ceil((ArtifactLevel / 15) * 2)


    local MainStat: string = nil;
    if SlotStats[Slot] ~= nil then
        MainStat = SlotStats[Slot];
    else
        local MainStatChoices = {}
        for Key in GameEnum.MainStats do
            if table.find(SlotStats, Key) then
                continue
            end

            table.insert(MainStatChoices, Key)
        end

        MainStat = MainStatChoices[math.random(1, #MainStatChoices)]
    end


    local SubStats = {}
    local StatKeys = {}
    for idx = 1, SubStatAmount do
        local RandomStat = GameEnum:Random('SubStats')
        if SubStats[RandomStat] then --(RandomStat == MainStat)
            repeat
                RandomStat = GameEnum:Random('SubStats')
            until SubStats[RandomStat] == nil
        end

        local RandomValue = math.ceil((ArtifactLevel / 20) * 2)

        SubStats[RandomStat] = RandomValue
        table.insert(StatKeys, RandomStat)
    end

    --
    while TotalBoosts > 0 do
        local RandomStat = StatKeys[Generator:NextInteger(1, #StatKeys)]

        TotalBoosts -= 1;
        SubStats[RandomStat] += 1
    end

    --
    return PlayerArtifactDataClass.new({
        Id = HttpService:GenerateGUID(false),
        Name = Name,
        Slot = Slot,
        Stats = {
            Main_Stat = {[MainStat] = DecideMainStatValue(MainStat, Level, GameEnum.Tiers[Tier])} :: Types.MainStat,
            Sub_Stats = SubStats :: Types.Substats,
        },
        Level = ArtifactLevel,
        Tier = Tier,
    })
end

function PlayerArtifactDataClass.GetMainStat(self: Types.PlayerArtifactDataClass): (string, number)
    local Key = next(self.__Stats.Main_Stat)

    return Key, self.__Stats.Main_Stat[Key]
end

function PlayerArtifactDataClass.Compress(self: Types.PlayerArtifactDataClass): {string | buffer}
    local BufferObj = buffer.create(16)
    local ArtifactId = ArtifactDatabase:GetIdFor(self.__Name) :: number
    if ArtifactId == nil then
        return false;
    end

    buffer.writeu8(BufferObj, 0, ArtifactId)
    buffer.writeu8(BufferObj, 1, self.__Level)
    buffer.writeu8(BufferObj, 2, self.__Slot)
    buffer.writeu8(BufferObj, 3, GameEnum.Tiers[self.__Tier])
    buffer.writeu8(BufferObj, 4, self.__Equipped and CharacterDatabase:GetIdForCharacter(self.__Equipped.Name :: string) or 0)

    local MainStatName, MainStatValue = self:GetMainStat()
    buffer.writeu8(BufferObj, 5, GameEnum.MainStats[MainStatName])
    buffer.writeu16(BufferObj, 6, MainStatValue * 10)

    local currentIndex = 8;
    for StatName, StatValue in self.__Stats.Sub_Stats do
        local Key = GameEnum.SubStats[StatName]

        buffer.writeu8(BufferObj, currentIndex, Key)
        buffer.writeu8(BufferObj, currentIndex + 1, StatValue)

        currentIndex += 2
    end

    return {self.__Id, BufferObj}
end

function PlayerArtifactDataClass.IsEquipped(self: Types.PlayerArtifactDataClass): boolean
    return self.__Equipped ~= nil
end

function PlayerArtifactDataClass.EquipTo(self: Types.PlayerArtifactDataClass, Agent: Types.PlayerAgentDataClass): ()
    if Agent == nil then
        self.__Equipped = nil

        return;
    end

    --
    local Unequipped = self.__Equipped
    if self.__Equipped then
        self.__Equipped:EquipArtifactToSlot(self.__Slot, nil)

        if self.__Equipped == Agent then
            self.__Equipped = nil

            return Agent
        end
    end

    local PreviousOne = Agent:EquipArtifactToSlot(self.__Slot, self)

    self.__Equipped = Agent

    return Unequipped, PreviousOne;
end

function PlayerArtifactDataClass.ToData(self: Types.PlayerArtifactDataClass): Types.PlayerArtifactData
    return {
        Id = self.__Id,
        Name = self.__Name,
        Level = self.__Level,
        Tier = self.__Tier,
        Slot = self.__Slot,
        Stats = self.__Stats,
        Equipped = self.__Equipped ~= nil and self.__Equipped.Name or nil,
    }
end

return PlayerArtifactDataClass;