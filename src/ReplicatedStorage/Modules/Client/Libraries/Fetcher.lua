local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local AgentDatabase = require(Shared.Database.Characters)
local WeaponDatabase = require(Shared.Database.Weapons)
local GameEnum = require(Shared.GameEnum)
local LocalData = require(script.Parent.LocalData)

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

function Fetcher:FetchAgents(): {any}
    local Data = Fetcher:SendRequest(GameEnum.FetchRequests.Agents)-- Request[2]
    local TranslatedData = {}

    for _, AgentData in Data do
        local Buffer = AgentData[1]
        local Artifacts = AgentData[2]

        table.insert(TranslatedData, {
            Name = AgentDatabase:GetCharacterFromId(buffer.readu8(Buffer, 0)),
            Level = buffer.readu8(Buffer, 1),
            Weapon = {
                Name = WeaponDatabase:GetWeaponFromId(buffer.readu8(Buffer, 2)),
                Level = buffer.readu8(Buffer, 3)
            },
            Artifacts = Artifacts,
        })
    end

    LocalData:SetAgents(TranslatedData :: {})

    return TranslatedData
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