--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)

local DataService = require(Services.Data.DataService)

-- Artifacts
local function AddArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Add, Artifact:Compress(), Agent.Name, Agent.Artifacts
    })
end

local function RemoveArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Remove, Artifact:Compress(), Agent.Name, Agent.Artifacts
    })
end

local function UpdateArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Update, Artifact:Compress(),
    })
end

--
local function AddDrive(Player: Player, Drive: Types.PlayerDriveDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Add, Drive:Compress(), Agent.Name,
    })
end

local function RemoveDrive(Player: Player, Drive: Types.PlayerDriveDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Remove, Drive:Compress(), Agent.Name
    })
end

local function UpdateDrive(Player: Player, Drive: Types.PlayerDriveDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.AgentEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Update, Drive:Compress(),
    })
end


--[[
    Handles setting up the builds & using the data from the player artifacts & more
]]
local Service = {}

function Service:Init()
    Network.new("UpdateAgent", 'Event')
    Network:On("UpdateAgent", Service.__HandleEvent)
end

function Service.__HandleEvent(Player: Player, Type: number, Request: {})
    if Type == GameEnum.AgentEvent.UpdateArtifactSlot then
        Service:SetAgentArtifactSlot(Player, Request[1], Request[2])
    elseif Type == GameEnum.AgentEvent.UpdateDrive then
        Service:SetAgentDrive(Player, Request[1], Request[2])
    end
end

function Service:SetAgentArtifactSlot(Player: Player, AgentName: string, ArtifactId: string)
    local Artifact = DataService:GetArtifacts(Player, function(Artifact)
        return Artifact.__Id == ArtifactId
    end, true) :: Types.PlayerArtifactDataClass

    local Agent = DataService:GetAgent(Player, AgentName)

    local UnequippedAgent, ReplacedSlotId = Artifact:EquipTo(Agent)

    if UnequippedAgent == Agent then
        RemoveArtifact(Player, Artifact, Agent)
    else
        AddArtifact(Player, Artifact, Agent)

        if UnequippedAgent then
            RemoveArtifact(Player, Artifact, UnequippedAgent)
        end
    end

    if ReplacedSlotId then
        local OldArtifact = DataService:GetArtifacts(Player, function(QueryArtifact)
            return QueryArtifact.__Id == ReplacedSlotId
        end, true) :: Types.PlayerArtifactDataClass

        OldArtifact:EquipTo(nil)

        UpdateArtifact(Player, OldArtifact)
    end
end

function Service:SetAgentDrive(Player: Player, AgentName: string, DriveId: string)
    local Drive = DataService:GetDrives(Player, function(QueryDrive)
        return QueryDrive.__Id == DriveId
    end, true) :: Types.PlayerDriveDataClass

    local Agent = DataService:GetAgent(Player, AgentName)

    local UnequippedAgent, ReplacedDriveId = Drive:EquipTo(Agent)

    if UnequippedAgent == Agent then
        RemoveDrive(Player, Drive, Agent)
    else
        AddDrive(Player, Drive, Agent)

        if UnequippedAgent then
            RemoveDrive(Player, Drive, UnequippedAgent)
        end
    end

    if ReplacedDriveId then
        local OldDrive = DataService:GetDrives(Player, function(QueryDrive)
            return QueryDrive.__Id == ReplacedDriveId
        end, true) :: Types.PlayerDriveDataClass

        OldDrive:EquipTo(nil)

        UpdateDrive(Player, OldDrive)
    end
end


return Service
