--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Data = require(ReplicatedStorage.Modules.Shared.Types.Data)

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

function LocalData:EditAgentArtifacts(AgentName: string, Artifacts: {}): ()
    for _, Agent in LocalData.__Cache["Agents"] do
        if Agent.Name == AgentName then
            Agent.Artifacts = Artifacts
        end
    end
end

function LocalData:EditAgentDrive(AgentName: string, Drive: Types.PlayerDriveData): ()
    for _, Agent in LocalData.__Cache["Agents"] do
        if Agent.Name == AgentName then
            Agent.Drive = Drive.Id
        end
    end
end

--
function LocalData:GetArtifacts()
    return LocalData.__Cache['Artifacts'] or {}
end

function LocalData:SetArtifacts(Data: {Types.PlayerArtifactData})
    LocalData.__Cache['Artifacts'] = Data

    print('Set artifacts', Data)
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

--
function LocalData:GetItemById(IdGiven: string): ((Types.PlayerArtifactData | Types.PlayerDriveData)?, ('Drive' | 'Artifact' | 'Item')?)
    for _, Item in LocalData:GetItems() do
        if Item.Name == IdGiven then
            return Item, 'Item'
        end
    end

    for _, Item in LocalData:GetArtifacts() do
        if Item.Id == IdGiven then
            return Item, 'Artifact'
        end
    end

    for _, Item in LocalData:GetDrives() do
        if Item.Id == IdGiven then
            return Item, 'Drive'
        end
    end

    return;
end
--
function LocalData:SetCurrencies(Payload: {}): ()
    LocalData.__Cache['Currencies'] = Payload
end

function LocalData:GetCurrencies(): {Money: number, Gems: number}
    return LocalData.__Cache['Currencies']
end

--
function LocalData:GetDrives()
    return LocalData.__Cache['Drives'] or {}
end

function LocalData:SetDrives(Data: {Types.PlayerDriveData})
    LocalData.__Cache['Drives'] = Data
end

function LocalData:GetDriveById(Id: string): Types.PlayerDriveData?
    for _, Artifact in LocalData.__Cache['Drives'] do
        if Artifact.Id == Id then
            return Artifact
        end
    end

    return
end

function LocalData:EditDrive(Artifact: Types.PlayerDriveData): ()
    for key, SavedArtifact in LocalData.__Cache['Drives'] do
        if SavedArtifact.Id == Artifact.Id then
            LocalData.__Cache['Drives'][key] = Artifact

            return
        end
    end
end

--
function LocalData:SetItems(Items: {Data.PlayerItemData})
    LocalData.__Cache['Items'] = table.freeze(Items)
end

function LocalData:GetItems(): {Data.PlayerItemData}
    return LocalData.__Cache['Items']
end

return LocalData