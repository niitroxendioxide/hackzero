local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local AgentDatabase = require(Shared.Database.Characters)
local WeaponDatabase = require(Shared.Database.Weapons)
local GameEnum = require(Shared.GameEnum)

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
    local Request = {GameEnum.FetchRequests.Agents, {}, false};

    table.insert(Fetcher.__Requests_Queued, Request);

    Network:Fire("DataFetchRequest", GameEnum.FetchRequests.Agents);

    repeat
        task.wait()
    until Request[3] == true;

    table.remove(Fetcher.__Requests_Queued, table.find(Fetcher.__Requests_Queued, Request));

    local Data = Request[2]
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

    print("Agent Data:", TranslatedData)

    return TranslatedData
end

return Fetcher