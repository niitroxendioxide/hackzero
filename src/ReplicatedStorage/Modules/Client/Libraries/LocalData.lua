--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local LocalData = {
    __Cache = {},
}

function LocalData:SetAgents(Data: {Types.ClientAgentData}): ()
    assert(typeof(Data) == "table", "Cannot overwrite the current agent table")

    LocalData.__Cache["Agents"] = table.freeze(Data)
end

function LocalData:GetAgents(): {Types.ClientAgentData}
    return LocalData.__Cache["Agents"]
end

function LocalData:GetArtifacts()
    return LocalData.__Cache['Artifacts']
end

function LocalData:SetArtifacts(Data: {Types.PlayerArtifactData})
    LocalData.__Cache['Artifacts'] = table.freeze(Data)
end

return LocalData