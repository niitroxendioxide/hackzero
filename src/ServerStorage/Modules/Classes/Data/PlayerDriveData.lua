--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local DriveTraits = require(Database.DriveTraits)
local AgentDatabase = require(Database.Characters)
local DrivesDatabase = require(Database.Drives)
local Statics = require(Database.Statics)

--
local PlayerDriveDataClass = {}
PlayerDriveDataClass.__index = PlayerDriveDataClass

function PlayerDriveDataClass.new(Data: Types.PlayerDriveData, AgentEquipped: Types.PlayerAgentDataClass?): Types.PlayerDriveDataClass
    local self = setmetatable({}, PlayerDriveDataClass)
    self.__Equipped = AgentEquipped

    self.__Id = Data.Id
    self.__Name = Data.Name
    self.__Level = Data.Level or 1
    self.__Experience = Data.Experience or 0

    return self
end

function PlayerDriveDataClass.randomize(Name: string): Types.PlayerDriveDataClass?
    if not DrivesDatabase:Verify(Name) then
        warn(`Cannot find drive by name {Name}. Check the spelling or make sure it exists`)

        return
    end

    --
    local Generator = Random.new()
    local Trait;

    if Generator:NextNumber(0, 100) < Statics.Drive_Trait_Chance then
        local PickedTrait = DriveTraits:GetRandom()

        Trait = PickedTrait;
    end

    --
    return PlayerDriveDataClass.new({
        Id = HttpService:GenerateGUID(false),
        Name = Name,
        Level = 1,
        Trait = Trait,
        Experience = 0,
    })
end

function PlayerDriveDataClass.IsEquipped(self: Types.PlayerDriveDataClass): (boolean)
    return self.__Equipped ~= nil
end

function PlayerDriveDataClass.EquipTo(self: Types.PlayerDriveDataClass, Agent: Types.PlayerAgentDataClass): ()
    if Agent == nil then
        self.__Equipped = nil

        return;
    end

    --
    local Unequipped = self.__Equipped
    if self.__Equipped then
        self.__Equipped:SetDrive(nil)

        if self.__Equipped == Agent then
            self.__Equipped = nil

            return Agent
        end
    end

    local PreviousOne = Agent:SetDrive(self.__Id)

    self.__Equipped = Agent

    return Unequipped, PreviousOne;
end

function PlayerDriveDataClass.Compress(self: Types.PlayerDriveDataClass): {string | buffer}
    local NameId = DrivesDatabase:GetIdForDrive(self.__Name)
    local EquippedId = self.__Equipped and AgentDatabase:GetIdForCharacter(self.__Equipped.Name)
    local TraitId = DriveTraits[self.__Trait] and DriveTraits[self.__Trait].Id or 0

    local DriveBuffer = buffer.create(6)

    buffer.writeu8(DriveBuffer, 0, NameId)
    buffer.writeu8(DriveBuffer, 1, self.__Level)
    buffer.writeu8(DriveBuffer, 2, TraitId)
    buffer.writeu8(DriveBuffer, 3, EquippedId or 0)
    buffer.writeu16(DriveBuffer, 4, self.__Experience)

    return {self.__Id, DriveBuffer}
end

function PlayerDriveDataClass.ToData(self: Types.PlayerDriveDataClass): Types.PlayerDriveData
    return {
        Id = self.__Id,
        Name = self.__Name,
        Trait = self.__Trait,
        Level = self.__Level,
        Experience = self.__Experience or 0,
        Equipped = (self.__Equipped and self.__Equipped.Name) or nil,
    }
end

return PlayerDriveDataClass