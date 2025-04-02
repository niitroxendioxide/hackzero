local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)

local Fetcher = {
    __Requests_Queued = {},
}

function Fetcher:Init()
    Network:On("DataFetchRequest", function(Type: string, Data: {})
        for _, Request in Fetcher.__Requests_Queued do
            if Request[1] == Type then
                Request[2] = Data
                Request[3] = true
            end
        end
    end)
end

function Fetcher:FetchAgents()
    local Request = {"Agents", {}, false};

    table.insert(Fetcher.__Requests_Queued, Request);

    Network:Fire("DataFetchRequest", "Agents");

    repeat
        task.wait()
    until Request[3] == true;

    table.remove(Fetcher.__Requests_Queued, table.find(Fetcher.__Requests_Queued, Request));

    return Request[2]
end

return Fetcher