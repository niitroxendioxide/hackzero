local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Agents)
local Math = require(Shared.Utility.Math)

--
local ItemsClass = {}
ItemsClass.__index = ItemsClass

function ItemsClass.new(Agent: Types.ServerAgentClass & Types.AgentClass): Types.AgentItemsClass & typeof(setmetatable({}, ItemsClass))
    local self = setmetatable({}, ItemsClass)
    self.__Name = Agent.Name
    self.__Level = Agent.__Level
    self.__Artifacts = {}
    self.__Drive = nil
    self.__PrecalculatedStats = {}
    self.__Artifact_Count = {}

    return self
end

function ItemsClass.BindArtifact(self: Types.AgentItemsClass, Artifact: Types.Artifact): ()
    local isValid = typeof(Artifact) == 'table' and Artifact.Slot <= 6 and Artifact.Slot >= 1;
    if not isValid then
        return warn(`Rejected binding artifact. Given data: {Artifact}`);
    end

    self.__Artifacts[Artifact.Slot] = Artifact;
    self.__Artifact_Count = {}

    return;
end

function ItemsClass.BindDrive(self: Types.AgentItemsClass, Drive: Types.Drive)
    local isValid = typeof(Drive) == 'table';
    if not isValid then
        return warn(`Rejected binding drive. Given data: {Drive}`);
    end

    self.__Drive = Drive;

    return;
end

function ItemsClass.GetArtifactStats(self: Types.AgentItemsClass): {[Types.Stat]: number}
    local Stats = {}

    if self.__Artifacts then
        Math:WriteArtifactsStats(Stats, self.__Artifacts)
    end

    return Stats
end

function ItemsClass.GetDriveStats(self: Types.AgentItemsClass): {[Types.Stat]: number}
    local Stats = {}

    if self.__Drive then
        Math:WriteDriveStats(Stats, self.__Drive)
    end

    return Stats
end

function ItemsClass.GetTotalAddedStat(self: Types.AgentItemsClass, Stat: Types.Stat): number
    if typeof(self.__Baked) ~= 'table' then
        self.__Baked = Math:CalculateStatsForAgent(self.__Name, self.__Level, self.__Drive, self.__Artifacts)
    end

    local Total = self.__Baked[Stat]

    return (Total or 0);
end

function ItemsClass.GetArtifactPieceEffects(self: Types.AgentItemsClass)
    if not next(self.__Artifact_Count) then
        local List = {}

        for _, ArtifactObject in self.__Artifacts do
            List[ArtifactObject.Name] = (List[ArtifactObject.Name] or 0) + 1
        end

        self.__Artifact_Count = List;
    end

    return self.__Artifact_Count
end

return ItemsClass