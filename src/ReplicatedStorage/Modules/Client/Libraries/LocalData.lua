--
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Shared = ReplicatedStorage.Modules.Shared

const GameEnum = require(Shared.GameEnum)
const Network = require(Shared.Network)
const Tasks = require(Shared.Types.Tasks)
const Types = require(Shared.Types)
const Data = require(Shared.Types.Data)
const Companions = require(Shared.Types.Companions)

--
const LocalData = {
    __Cache = {},
    __Stage_Data = {},
    __MissionId = nil :: string,
    __Lock = {},
}

function LocalData:AllocateAllAcceptedTasks(Value: { Tasks.AgencyTaskMission })
    LocalData.__Lock.Tasks = false;
    LocalData.__Cache.AcceptedTasks = Value;
end

function LocalData:GetAllAcceptedTasks(Fetch: boolean?): { Tasks.AgencyTaskMission }
    if LocalData.__Lock.Tasks then
        return
    end

    if Fetch then
        LocalData.__Lock.Tasks = true;

        Network:Fire("AgencyTasks", GameEnum.AgencyTaskEvent.RetrieveAllAccepted)

        while (LocalData.__Lock.Tasks == true) do
            task.wait() 
        end
    end

    return LocalData.__Cache.AcceptedTasks;
end

function LocalData:AllocateUUIDMission(UUID: string, Value: any)
    if not LocalData.__Cache.ProceduralMissions then
        LocalData.__Cache.ProceduralMissions = {}
    end

    LocalData.__Cache.ProceduralMissions[UUID] = Value;
end

function LocalData:GetUUIDMission(UUID: string, Yield: boolean?, MaxYieldTime: number?): any
    if not LocalData.__Cache.ProceduralMissions then
        return
    end
    
    local Value = LocalData.__Cache.ProceduralMissions[UUID]
    
    if not Yield then
        return Value;
    end

    if Value == nil then
        local Started = os.clock();
        repeat
            Value = LocalData.__Cache.ProceduralMissions[UUID]
            task.wait(0.1)
        until Value ~= nil or (MaxYieldTime ~= nil and (os.clock() - Started) > MaxYieldTime)
    end

    return Value
end

function LocalData:AllocateDialogueData(New_Dialogue_Data: { any })
    assert(typeof(New_Dialogue_Data) == 'table', "Must pass in a table to allocate dialogue data")

    if not LocalData.__Cache.AllocatedDialogue then
        LocalData.__Cache.AllocatedDialogue = New_Dialogue_Data
    end
end

function LocalData:GetAllocatedDialogueData()
    return LocalData.__Cache.AllocatedDialogue
end

function LocalData:SetAgents(Data: {Types.ClientAgentData}): ()
    assert(typeof(Data) == "table", "Cannot overwrite the current agent table")

    LocalData.__Cache["Agents"] = Data
end

function LocalData:GetAgents(): {Types.ClientAgentData}
    return LocalData.__Cache["Agents"] or {}
end

function LocalData:SetMissionId(MissionId: string)
    LocalData.__MissionId = MissionId
end

function LocalData:SetStageData(Stage: string, Act: string)
    LocalData.__Stage_Data.Stage = Stage
    LocalData.__Stage_Data.Act = Act
end

--[[
    @return Stage (string)
    @return Act (string)
]]
function LocalData:GetStageData(): { Stage: string, Act: string, MissionId: string }
    return {
        Stage = LocalData.__Stage_Data.Stage, 
        Act = LocalData.__Stage_Data.Act,
        MissionId = LocalData.__MissionId,
    }
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

function LocalData:GetCompanion(Id: string): Companions.ClientCompanionData?
    for _, Companion in LocalData.__Cache['Companions'] do
        if Companion.Id == Id then
            return Companion
        end
    end

    return;
end

function LocalData:EditCompanion(Companion: Companions.ClientCompanionData): ()
    for subid, Comp in LocalData.__Cache['Companions'] do
        if Comp.Id == Companion.Id then
            LocalData.__Cache['Companions'][subid] = Companion

            return
        end
    end
end

function LocalData:SetCompanionData(Data: {Companions.ClientCompanionData})
    LocalData.__Cache['Companions'] = Data
end

function LocalData:GetAllCompanions(): {Companions.ClientCompanionData}
    return LocalData.__Cache['Companions'] or {}
end

--
function LocalData:GetArtifacts()
    return LocalData.__Cache['Artifacts'] or {}
end

function LocalData:SetArtifacts(Data: {Types.PlayerArtifactData})
    LocalData.__Cache['Artifacts'] = Data
end

function LocalData:GetArtifactById(Id: string): Types.PlayerArtifactData?
    for _, Artifact in (LocalData.__Cache['Artifacts'] or {}) do
        if Artifact.Id == Id then
            return Artifact
        end
    end

    return
end

function LocalData:EditArtifact(Artifact: Types.PlayerArtifactData): ()
    for key, SavedArtifact in (LocalData.__Cache['Artifacts'] or {}) do
        if SavedArtifact.Id == Artifact.Id then
            LocalData.__Cache['Artifacts'][key] = Artifact

            return
        end
    end
end

--
function LocalData:GetItemById(IdGiven: string): ((Types.PlayerArtifactData & Types.PlayerDriveData & Data.PlayerItemData)?, ('Drive' | 'Artifact' | 'Item')?)
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