
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

function PlayerAgentDataClass.ToData(self: Types.PlayerAgentDataClass): Types.PlayerAgentData
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

        Name = self.Name,
        Level = self.Level,
        Obtained = self.ObtainmentDate,
        Skins = self.Skins,
        Experience = self.Experience,
    })
end

function PlayerAgentDataClass.Compress(self: Types.PlayerAgentDataClass)
    local Id = CharactersDatabase:GetIdForCharacter(self.Name)

    local DataBuffer = buffer.create(4)
    buffer.writeu8(DataBuffer, 0, Id)
    buffer.writeu8(DataBuffer, 1, self.Level)
    buffer.writeu16(DataBuffer, 2, self.Experience)

    return {DataBuffer, self.Artifacts, self.Drive}
end

return PlayerAgentDataClass
