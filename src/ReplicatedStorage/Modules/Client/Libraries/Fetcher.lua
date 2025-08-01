local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Network = require(Shared.Network)
local AgentDatabase = require(Shared.Database.Characters)
local GameEnum = require(Shared.GameEnum)
local LocalData = require(script.Parent.LocalData)

local DataTypes = require(Shared.Types.Data)

local Fetcher = {
    __Requests_Queued = {},
}

function Fetcher:Init()
    Network:On("DataFetchRequest", function(Type: number, Data: {})
        for _, Request in Fetcher.__Requests_Queued do
            if Request[1] == Type then
                Request[2] = Data
                Request[3] = true
            end
        end
    end)
end

function Fetcher:BufferListToData(AgentData: {}): Types.ClientAgentData
    local Buffer = AgentData[1]
    local Artifacts = AgentData[2]
    local DriveId = AgentData[3]

    local SkillLevels = {
        Basic_Attack = buffer.readu8(Buffer, 2),
        Special = buffer.readu8(Buffer, 3),
        Ultimate = buffer.readu8(Buffer, 4),
    }

    local Ascensions = buffer.readu8(Buffer, 5)

    return {
        Name = AgentDatabase:GetCharacterFromId(buffer.readu8(Buffer, 0)),
        Level = buffer.readu8(Buffer, 1),
        Drive = DriveId,
        Artifacts = Artifacts,
        Ascensions = Ascensions,
        Skills = SkillLevels,
        Experience = buffer.readu16(Buffer, 6)
    }
end

function Fetcher:FetchAgents(): {any}
    local Data = Fetcher:SendRequest(GameEnum.FetchRequests.Agents)-- Request[2]
    local TranslatedData = {}

    for _, AgentData in Data do
        table.insert(TranslatedData, Fetcher:BufferListToData(AgentData))
    end

    LocalData:SetAgents(TranslatedData)

    return TranslatedData
end

function Fetcher:FetchStages(): {any}
    local Data = Fetcher:SendRequest(GameEnum.FetchRequests.Stages)-- Request[2]

    return Data
end


function Fetcher:FetchParties(): {any}
    local RetreivedData = Fetcher:SendRequest(GameEnum.FetchRequests.Parties, "Party")
    local New = {}

    for _, Party in RetreivedData do
        table.insert(New, {
            Code = Party[1];
            Owner = Players:GetPlayerByUserId(Party[2]).Name;
            PlayerCount = `{Party[3]} / {Party[4]}`;
            Players = Party[3];
            MaxPlayers = Party[4];
            AverageLevel = Party[5];
        })
    end

    return New
end

function Fetcher:FetchQuests(Type: string?): {DataTypes.QuestData}
    local RetreivedData = Fetcher:SendRequest(GameEnum.FetchRequests.Quests)
    local New = {}

    for _, QuestObjData in RetreivedData do
        table.insert(New, {
            Rewards = QuestObjData.Rewards,
            Progress = QuestObjData.Progress,
            Description = QuestObjData.Description,
            Goals = QuestObjData.Goals,
            Name = QuestObjData.Name,
            Id = QuestObjData.Id,
            Type = GameEnum.KeyLookup(GameEnum.QuestTypes, QuestObjData.Type),
        })
    end

    return New
end

function Fetcher:SendRequest(Type: number, Event: string?)
    local Request = {Type, {}, false};

    table.insert(Fetcher.__Requests_Queued, Request);

    Network:Fire(Event or "DataFetchRequest", Type);
    repeat
        task.wait()
    until Request[3] == true;

    table.remove(Fetcher.__Requests_Queued, table.find(Fetcher.__Requests_Queued, Request));

    return Request[2]
end

return Fetcher