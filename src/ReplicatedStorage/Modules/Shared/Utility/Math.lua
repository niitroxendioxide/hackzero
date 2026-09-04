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
            local BaseValue = AgentStats[StatRaw] or 1
            local ValuePercent = (StatBuffValue / 100)

            local AddedPercentBoost = BaseValue * ValuePercent
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
            local SlotCount = 1

            for _, OtherItem in Artifacts do
                if OtherItem.Id == ArtifactObject.Id then continue end

                if OtherItem.Name == ArtifactObject.Name then
                    SlotCount += 1
                end
            end

            if SlotCount >= 2 then
                for StatName, StatValue in Data.Piece_Effects.Two_Piece do
                    if StatsTable[StatName] == nil then
                        StatsTable[StatName] = 0
                    end

                    StatsTable[StatName] += StatValue
                end
            end

            if SlotCount >= 4 then
                for StatName, StatValue in Data.Piece_Effects.Four_Piece do
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

    @param First The 2 bit number (0-3), stored in the high bits
    @param Second The 6 bit number (0-63), stored in the low bits
    @param GivenBuffer? Optional parameter to override the creation of a new buffer
    @param GivenOffset? Optional parameter to override the usage of the zero offset

    Both values are masked, not validated: anything wider is silently truncated.

    ```lua
        -- On the server
        local Buffer = Math:Encodeu2u6(2, 45)
        Event:Fire(Player, Buffer)

        -- On some client
        local Type, Amount = Math:Decodeu2u6(Buffer)
        print(Type, Amount) -- 2, 45
    ```

    @return Buffer The buffer in which the numbers were encoded
]]
function Math:Encodeu2u6(First: number, Second: number, GivenBuffer: buffer?, GivenOffset: number?): buffer
    local FirstMask = bit32.band(First or 0, 0x03)
    local SecondMask = bit32.band(Second or 0, 0x3F)

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

--[[
    Pack the movement state of an agent into the single byte carried by every
    Move/Stop/Rotate/PivotTo packet, so the receiver knows *which* agent the
    packet describes instead of guessing from its own idea of the active one.

    bits 6-7  AgentId - 1 (0-3)
    bit  0    Moving
    bit  1    Sprint
    bit  2    Jog
    bits 3-5  reserved
]]
function Math:EncodeMovementByte(AgentId: number, Moving: boolean, Sprint: boolean, Jog: boolean): number
    assert(AgentId >= 1 and AgentId <= 4, `AgentId {AgentId} does not fit in the 2 bit movement byte field`)

    local Flags = 0
    if Moving then Flags = bit32.bor(Flags, 0x01) end
    if Sprint then Flags = bit32.bor(Flags, 0x02) end
    if Jog then Flags = bit32.bor(Flags, 0x04) end

    return bit32.bor(bit32.lshift(AgentId - 1, 6), Flags)
end

function Math:DecodeMovementByte(Byte: number): (number, boolean, boolean, boolean)
    local AgentId = bit32.rshift(Byte, 6) + 1
    local Flags = bit32.band(Byte, 0x3F)

    return AgentId,
        bit32.band(Flags, 0x01) ~= 0,
        bit32.band(Flags, 0x02) ~= 0,
        bit32.band(Flags, 0x04) ~= 0
end

--[[
    Frame rate independent lerp alpha. Rate is roughly "how many e-folds per
    second" -- higher converges faster. Promoted out of Camera.lua so the
    replication smoothing can share it.
]]
function Math:SmoothAlpha(Rate: number, Delta: number): number
    return 1 - math.exp(-Rate * Delta)
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

--[[
    Pull a point back inside a box, keeping its rotation. Companion to
    IsPointInBox -- used so an assist/switch reposition can never drop an agent
    outside the fight area it is bound to.

    @param Point The point to clamp. A CFrame keeps its rotation, a Vector3 comes back as a Vector3.
    @param Box The BasePart defining the area
    @param SizeModifier? Same meaning as in IsPointInBox
    @param Inset? Studs to keep away from the wall, so the agent is not clipped into it
]]
function Math:ClampPointToBox(Point: CFrame | Vector3, Box: BasePart, SizeModifier: number?, Inset: number?): CFrame | Vector3
    local IsCFrame = typeof(Point) == "CFrame"
    local Position = IsCFrame and (Point :: CFrame).Position or (Point :: Vector3)

    local BoxCFrame = Box:GetPivot()
    local HalfSize = (Box.Size * (SizeModifier or 1)) / 2

    local Margin = Inset or 0
    local Limit = Vector3.new(
        math.max(HalfSize.X - Margin, 0),
        math.max(HalfSize.Y - Margin, 0),
        math.max(HalfSize.Z - Margin, 0)
    )

    local Offset = BoxCFrame:PointToObjectSpace(Position)
    local Clamped = Vector3.new(
        math.clamp(Offset.X, -Limit.X, Limit.X),
        math.clamp(Offset.Y, -Limit.Y, Limit.Y),
        math.clamp(Offset.Z, -Limit.Z, Limit.Z)
    )

    local WorldPosition = BoxCFrame:PointToWorldSpace(Clamped)

    if not IsCFrame then
        return WorldPosition
    end

    return (Point :: CFrame).Rotation + WorldPosition
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

    -- EncodeCFrame stores atan2(LookVector.X, LookVector.Z), so the heading is
    -- rebuilt as (sin, 0, cos) to match. Building it with CFrame.Angles instead
    -- yields the negated LookVector, i.e. a 180 degree flip.
    local Rebuilt = CFrame.lookAlong(Vector3.new(X, Y, Z), Vector3.new(math.sin(Angle), 0, math.cos(Angle)))

    return Rebuilt, (Offset::number) + 12
end

return Math