local ReplicatedStorage = game:GetService("ReplicatedStorage")
--
local DefaultTypes = require(ReplicatedStorage.Modules.Shared.Types)

--
local Data = {
    __Agents = {},
    __Artifacts = {},
    __Drives = {},
}


function Data:GetArtifactById(Player: Player, Id: string): DefaultTypes.PlayerArtifactData?
    for _, Artifact in (Data.__Artifacts[Player] or {}) do
        if Artifact.Id == Id then
            return Artifact
        end
    end

    return;
end

function Data:GetAgentData(Player: Player, Name: string): DefaultTypes.ClientAgentData?
    for _, Agent in (Data.__Agents[Player] or {}) do
        if Agent.Name == Name then
            return Agent
        end
    end

    return;
end

function Data:GetDriveById(Player: Player, Id: string): DefaultTypes.PlayerDriveData?
    for _, Drive in (Data.__Drives[Player] or {}) do
        if Drive.Id == Id then
            return Drive
        end
    end

    return;
end

function Data:SetData(Player: Player, Agents: {}, Drives: {}, Artifacts: {})
    Data.__Agents[Player] = Agents
    Data.__Drives[Player] = Drives
    Data.__Artifacts[Player] = Artifacts
end

return Data
