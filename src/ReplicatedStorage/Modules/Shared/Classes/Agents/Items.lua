local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Agents)

--
local ItemsClass = {}
ItemsClass.__index = ItemsClass

function ItemsClass.new(): Types.AgentItemsClass & typeof(setmetatable({}, ItemsClass))
    local self = setmetatable({}, ItemsClass)
    self.__Artifacts = {}
    self.__Drive = {}

    return self
end

function ItemsClass.BindArtifact(self: Types.AgentItemsClass, Artifact: Types.Artifact): ()
    local isValid = typeof(Artifact) == 'table' and Artifact.Slot <= 6 and Artifact.Slot >= 1;
    if not isValid then
        return warn(`Rejected binding artifact. Given data: {Artifact}`);
    end

    self.__Artifacts[Artifact.Slot] = Artifact;

    return;
end

function ItemsClass.BindDrive(self: Types.AgentItemsClass, Drive: Types.Drive)
    local isValid = typeof(Drive) == 'table';
    if not isValid then
        return warn(`Rejected binding artifact. Given data: {Drive}`);
    end

    self.__Drive = Drive;

    return;
end

function ItemsClass.GetArtifactStats(self: Types.AgentItemsClass): {[Types.Stat]: number}
    local Stats = {}

    warn("Hi do the math for artifacts")
    for id, Artifact in self.__Artifacts do
        
    end

    return Stats
end

function ItemsClass.GetDriveStats(self: Types.AgentItemsClass): {[Types.Stat]: number}
    local Stats = {}

    --
    warn("Hi do the math for Drives")

    return Stats
end

function ItemsClass.GetTotalAddedStat(self: Types.AgentItemsClass, Stat: Types.Stat): number
    local ArtifactStats = self:GetArtifactStats()
    local DriveStats = self:GetDriveStats()
    
    local Total = (DriveStats[Stat] or 0) + (ArtifactStats[Stat] or 0)

    return Total;
end

return ItemsClass