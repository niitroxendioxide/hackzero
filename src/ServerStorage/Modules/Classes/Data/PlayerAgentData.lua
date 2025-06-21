
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local CharactersDatabase = require(Database.Characters)

local PlayerAgentDataClass = {}
PlayerAgentDataClass.__index = PlayerAgentDataClass;

function PlayerAgentDataClass.new(Name: string, Level: number, Date: number)
    local self = setmetatable({}, PlayerAgentDataClass)
    self.Name = Name
    self.Experience = 0
    self.Level = Level
    self.Drive = nil
    self.Artifacts = {}
    self.Skins = {}
    self.Skills = {
        Basic_Attack = 0,
        Special = 0,
        Ultimate = 0,
    }
    self.Ascensions = 0
    self.ObtainmentDate = Date

    return self
end

function PlayerAgentDataClass.SetDrive(self: Types.PlayerAgentDataClass, DriveId: string): string
    local Previous = self.Drive

    self.Drive = DriveId

    return Previous;
end

function PlayerAgentDataClass.SetArtifacts(self: Types.PlayerAgentDataClass, Artifacts: {string}): ()
    local Saved = {}
    for k, Artifact in Artifacts do
        local Slot = tonumber(k)
        if Slot > 6 or Slot < 1 then
            warn("Invalid artifact set given. Artifact:", Artifact, "slot is invalid {", Slot, "}")
            return
        end

        Saved[Slot] = Artifact
    end

    self.Artifacts = Saved;
end

function PlayerAgentDataClass.SetSkill(self: Types.PlayerAgentDataClass, SkillName: string, SkillLevel: number)
    assert(SkillLevel <= 20 and SkillLevel >= 0, 'Skill level out of bounds');

    self.Skills[SkillName] = SkillLevel
end

function PlayerAgentDataClass.EquipArtifactToSlot(self: Types.PlayerAgentDataClass, SlotId: number, Artifact: Types.PlayerArtifactDataClass?): ()
    if Artifact then
        local Previous = self.Artifacts[SlotId]
        self.Artifacts[SlotId] = Artifact.__Id

        return Previous;
    else
        local Previous = self.Artifacts[SlotId]
        self.Artifacts[SlotId] = nil

        return Previous
    end
end

function PlayerAgentDataClass.SetAscensions(self: Types.PlayerAgentDataClass, Amount: number)
    self.Ascensions = math.clamp(Amount, 0, 6)
end

function PlayerAgentDataClass.ToData(self: Types.PlayerAgentDataClass): Types.PlayerAgentData
    print(self.Ascensions)

    return table.freeze({
        Drive = self.Drive,
        Artifacts = {
            [1] = self.Artifacts[1],
            [2] = self.Artifacts[2],
            [3] = self.Artifacts[3],
            [4] = self.Artifacts[4],
            [5] = self.Artifacts[5],
            [6] = self.Artifacts[6],
        },

        Ascensions = self.Ascensions,
        Skills = self.Skills,

        Name = self.Name,
        Level = self.Level,
        Obtained = self.ObtainmentDate,
        Skins = self.Skins,
        Experience = self.Experience,
    })
end

function PlayerAgentDataClass.Compress(self: Types.PlayerAgentDataClass)
    local Id = CharactersDatabase:GetIdForCharacter(self.Name)

    local DataBuffer = buffer.create(8)
    buffer.writeu8(DataBuffer, 0, Id)
    buffer.writeu8(DataBuffer, 1, self.Level)
    buffer.writeu8(DataBuffer, 2, self.Skills.Basic_Attack)
    buffer.writeu8(DataBuffer, 3, self.Skills.Special)
    buffer.writeu8(DataBuffer, 4, self.Skills.Ultimate)
    buffer.writeu8(DataBuffer, 5, self.Ascensions)
    buffer.writeu16(DataBuffer, 6, self.Experience)

    return {DataBuffer, self.Artifacts, self.Drive}
end

return PlayerAgentDataClass
