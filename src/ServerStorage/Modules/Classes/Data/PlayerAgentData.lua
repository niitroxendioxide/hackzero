
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local WeaponsDatabase = require(Database.Weapons)
local ArtifactsDatabase = require(Database.Artifacts)
local CharactersDatabase = require(Database.Characters)

local PlayerAgentDataClass = {}
PlayerAgentDataClass.__index = PlayerAgentDataClass;

function PlayerAgentDataClass.new(Name: string, Level: number, Date: number)
    local self = setmetatable({}, PlayerAgentDataClass)
    self.Name = Name
    self.Level = Level
    self.Weapon = {}
    self.Artifacts = {}
    self.Skins = {}
    self.ObtainmentDate = Date

    return self
end

function PlayerAgentDataClass.SetWeapon(self: Types.PlayerAgentDataClass, Name: string, Level: number)
    if Level <= 0 or Level > 60 then
        warn("Level given is off limits")

        return
    end

    if not WeaponsDatabase:Verify(Name) then
        warn("Invalid weapon passed.", Name, "not found in database")
        return
    end

    self.Weapon = {
        Name = Name,
        Level = Level,
    }
end

function PlayerAgentDataClass.SetArtifacts(self: Types.PlayerAgentDataClass, Artifacts: {Types.ArtifactDataClass}): ()
    for key, Artifact in Artifacts do
        if Artifact.Slot > 6 or Artifact.Slot < 1 then
            warn("Invalid artifact set given. Artifact:", key, "slot is invalid {", Artifact.Slot, "}")
            return
        end

        if not ArtifactsDatabase:Verify(Artifact.Name) then
            warn("Invalid artifact name")

            return
        end
    end

    self.Artifacts = Artifacts;
end

function PlayerAgentDataClass.ToData(self: Types.PlayerAgentDataClass): Types.PlayerAgentData
    return table.freeze({
        Weapon = self.Weapon,
        Artifacts = self.Artifacts,

        Name = self.Name,
        Level = self.Level,
        Obtained = self.ObtainmentDate,
        Skins = self.Skins,
    })
end

function PlayerAgentDataClass.Compress(self: Types.PlayerAgentDataClass)
    local DataBuffer = buffer.create(4)
    buffer.writeu8(DataBuffer, 0, CharactersDatabase:GetIdForCharacter(self.Name))
    buffer.writeu8(DataBuffer, 1, self.Level)
    buffer.writeu8(DataBuffer, 2, WeaponsDatabase:GetIdForWeapon(self.Weapon.Name) or 0)
    buffer.writeu8(DataBuffer, 3, self.Weapon.Level or 1)

    return {DataBuffer, self.Artifacts}
end

return PlayerAgentDataClass
