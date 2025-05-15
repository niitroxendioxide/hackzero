--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)

--
local LocalData = {
    __Cache = {},
}

function LocalData:SetAgents(Data: {Types.ClientAgentData}): ()
    assert(typeof(Data) == "table", "Cannot overwrite the current agent table")

    LocalData.__Cache["Agents"] = Data
end

function LocalData:GetAgents(): {Types.ClientAgentData}
    return LocalData.__Cache["Agents"] or {}
end

function LocalData:GetAgent(Name: string): Types.ClientAgentData?
    for _, Agent in LocalData.__Cache['Agents'] do
        if Agent.Name == Name then
            return Agent;
        end
    end

    return
end

function LocalData:EditAgentArtifacts(AgentName: string, Artifacts: {})
    for _, Agent in LocalData.__Cache["Agents"] do
        if Agent.Name == AgentName then
            Agent.Artifacts = Artifacts
        end
    end
end

--
function LocalData:GetArtifacts()
    return LocalData.__Cache['Artifacts'] or {}
end

function LocalData:SetArtifacts(Data: {Types.PlayerArtifactData})
    LocalData.__Cache['Artifacts'] = Data
end

function LocalData:GetArtifactById(Id: string): Types.PlayerArtifactData?
    for _, Artifact in LocalData.__Cache['Artifacts'] do
        if Artifact.Id == Id then
            return Artifact
        end
    end

    return
end

function LocalData:EditArtifact(Artifact: Types.PlayerArtifactData): ()
    for key, SavedArtifact in LocalData.__Cache['Artifacts'] do
        if SavedArtifact.Id == Artifact.Id then
            LocalData.__Cache['Artifacts'][key] = Artifact

            return
        end
    end
end

return LocalData