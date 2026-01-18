local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Math = {}

--
local Database = script.Parent.Parent.Database
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local ArtifactDatabase = require(Database.Artifacts)
local DrivesDatabase = require(Database.Drives)
local AgentsDatabase = require(Database.Characters)

--
function Math:ApplyPercents(StatsTable: { [string]: number }, AgentStats: {})
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
        local ArtifactTier = ArtifactObject.Tier :: number

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
            local TickTable = Statics.SubStatIncreases[SubName]
            if not TickTable then
                continue
            end

            local StrToIdx = typeof(ArtifactTier) == 'string' and GameEnum.Tiers[ArtifactTier] or ArtifactTier
            local Amount = TickTable[StrToIdx] * SubValue

            if StatsTable[SubName] == nil then
                StatsTable[SubName] = 0
            end

            StatsTable[SubName] += Amount
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


--[[
    Encode two numbers into an unsigned 8 bit integer

    @param First The 6 bit number to be encoded into an u8
    @param Second The 2 bit number to be encoded into an u8
    @param GivenBuffer? Optional parameter to override the creation of a new buffer
    @param GivenOffset? Optional parameter to override the usage of the zero offset

    ```lua
        -- On the server
        local Buffer = Math:Encodeu2u6(64, 2)
        Event:Fire(Player, Buffer)

        -- On some client
        local Amount, Type = Math:Decodeu2u6(Buffer)
        print(Amount, Type) -- 64, 2
    ```

    @return Buffer The buffer in which the numbers were encoded
]]
function Math:Encodeu2u6(First: number, Second: number, GivenBuffer: buffer?, GivenOffset: number?): buffer
    local FirstMask = bit32.band(First, 0x03)
    local SecondMask = bit32.band(Second, 0x3F)

    local BorResult = bit32.bor(bit32.lshift(FirstMask, 6), SecondMask)

    local BufferObj = GivenBuffer or buffer.create(1)
    buffer.writeu8(BufferObj, GivenOffset or 0, BorResult)

    return BufferObj
end

function Math:Decodeu2u6(obj: buffer, offset: number?): (number, number)
    local Byte = buffer.readu8(obj, offset or 0)

    local ExtractedFirst = bit32.rshift(Byte, 6)
    local ExtractedSecond = bit32.band(Byte, 0x3F)

    return ExtractedFirst, ExtractedSecond
end

function Math:IsPointInBox(Point: CFrame | Vector3, Box: BasePart, SizeModifier: number?)
    if typeof(Point) == "CFrame" then
        Point = Point.Position
    end

    local BoxCFrame = Box:GetPivot()
    local BoxSize = Box.Size * (SizeModifier or 1)

    local Offset = BoxCFrame:PointToObjectSpace(Point)

    local HalfSize = BoxSize / 2

    return (math.abs(Offset.X) <= HalfSize.X and
           math.abs(Offset.Y) <= HalfSize.Y and
           math.abs(Offset.Z) <= HalfSize.Z)
end

function Math:EncodeCFrame(At: CFrame, Buffer: buffer, Offset: number?)
    Offset = Offset or 1

    local Angle = math.atan2(At.LookVector.X, At.LookVector.Z)
    buffer.writef32(Buffer, (Offset::number) + 0, At.X)
    buffer.writef32(Buffer, (Offset::number) + 4, At.Z)
    buffer.writei16(Buffer, (Offset::number) + 8, At.Y * 100)
    buffer.writei16(Buffer, (Offset::number) + 10, Angle * 5100)
end

function Math:DecodeCFrame(Buffer: buffer, Offset: number)
    Offset = Offset or 1

    local X = buffer.readf32(Buffer, (Offset::number) + 0)
    local Z = buffer.readf32(Buffer, (Offset::number) + 4)
    local Y = buffer.readi16(Buffer, (Offset::number) + 8) / 100
    local Angle = buffer.readi16(Buffer, (Offset::number) + 10) / 5100

    local Rebuilt = CFrame.new(X, Y, Z) * CFrame.Angles(0, Angle, 0)

    return Rebuilt, (Offset::number) + 12
end

return Math