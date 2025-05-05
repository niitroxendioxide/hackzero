--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local LocalData = {
    __Cache = {}
}

function LocalData:SetAgents(Data: {Types.ClientAgentData}): ()
    assert(typeof(Data) == "table", "Cannot overwrite the current agent table")

    LocalData.__Cache["Agents"] = table.freeze(Data)
end

function LocalData:GetAgents(): {Types.ClientAgentData}
    return LocalData.__Cache["Agents"]
end

return LocalData