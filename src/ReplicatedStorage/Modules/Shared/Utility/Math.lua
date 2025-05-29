local Math = {}

--
local Database = script.Parent.Parent.Database
local ArtifactDatabase = require(Database.Artifacts)
local DrivesDatabase = require(Database.Drives)
local AgentsDatabase = require(Database.Characters)

--
function Math:ApplyPercents(StatsTable: {}, AgentStats: {})

    for StatBuffName, StatBuffValue in StatsTable do
        if string.match(StatBuffName, "%%") then
            local StatRaw = string.gsub(StatBuffName, "%%", "")

            local AddedPercentBoost = AgentStats[StatRaw] * (StatBuffValue / 100)
            if not StatsTable[StatRaw] then
                StatsTable[StatRaw] = 0
            end

            StatsTable[StatRaw] += AddedPercentBoost
            StatsTable[StatBuffName] = nil
        end
    end
end

function Math:WriteArtifactsStats(StatsTable: {}, Artifacts)
    local Effects = {}
    for _, ArtifactObject in Artifacts do
        local Data = ArtifactDatabase:GetArtifactData(ArtifactObject.Name)

        local MainStatName = next(ArtifactObject.Stats.Main_Stat)
        local MainStatValue = ArtifactObject.Stats.Main_Stat[MainStatName]

        if Effects[Data.Name] == nil then
            local SlotCount = 0

            for _, OtherItem in Artifacts do
                if OtherItem.Id == ArtifactObject.Id then continue end

                if OtherItem.Name == ArtifactObject.Name then
                    SlotCount += 1
                end
            end

            for StatName, StatValue in Data.Piece_Effects.Two_Piece do
                if StatsTable[StatName] == nil then
                    StatsTable[StatName] = 0
                end

                StatsTable[StatName] += StatValue
            end

            if SlotCount >= 4 then
                for StatName, StatValue in Data.Piece_Effects.Two_Piece do
                    if StatsTable[StatName] == nil then
                        StatsTable[StatName] = 0
                    end

                    StatsTable[StatName] += StatValue
                end
            end

            Effects[Data.Name] = SlotCount
        end

        if StatsTable[MainStatName] == nil then
            StatsTable[MainStatName] = 0
        end

        StatsTable[MainStatName] += MainStatValue

        --
        for SubName, SubValue in ArtifactObject.Stats.Sub_Stats do
            if StatsTable[SubName] == nil then
                StatsTable[SubName] = 0
            end

            StatsTable[SubName] += SubValue
        end
    end
end

function Math:WriteDriveStats(StatsTable: {}, Drive)
    local Level = Drive.Level
    local DriveData = DrivesDatabase:GetDriveData(Drive.Name)
    local MainStatName = DriveData.Main_Stat.StatName
    local MainStatValue = DriveData.Main_Stat.Base + (DriveData.Main_Stat.UpgradePerLevel) * Level

    if StatsTable[MainStatName] == nil then
        StatsTable[MainStatName] = 0
    end

    StatsTable[MainStatName] += MainStatValue

    local SubStatName = DriveData.Advanced_Stat.StatName
    local SubStatValue = DriveData.Advanced_Stat.Base + (DriveData.Advanced_Stat.UpgradePerAscension) * (Level // 10)

    if StatsTable[SubStatName] == nil then
        StatsTable[SubStatName] = 0
    end

    StatsTable[SubStatName] += SubStatValue
end

function Math:CalculateStatsForAgent(AgentName: string, Level: number, Drive, Artifacts)
    local AgentStats = AgentsDatabase:GetStatsAtLevel(AgentName, Level)
    local StatBuffs = {}

    if Artifacts then
        Math:WriteArtifactsStats(StatBuffs, Artifacts)
    end

    if Drive then
        Math:WriteDriveStats(StatBuffs, Drive)
    end

    Math:ApplyPercents(StatBuffs, AgentStats)

    return StatBuffs
end


function Math:Encodeu2u6(First: number, Second: number): buffer
    local FirstMask = bit32.band(First, 0x03)
    local SecondMask = bit32.band(Second, 0x3F)

    local BorResult = bit32.bor(bit32.lshift(FirstMask, 6), SecondMask)

    local BufferObj = buffer.create(1)
    buffer.writeu8(BufferObj, 0, BorResult)

    return BufferObj
end

function Math:Decodeu2u6(obj: buffer): (number, number)
    local Byte = buffer.readu8(obj, 0)

    local ExtractedFirst = bit32.rshift(Byte, 6)
    local ExtractedSecond = bit32.band(Byte, 0x3F)

    return ExtractedFirst, ExtractedSecond
end

return Math