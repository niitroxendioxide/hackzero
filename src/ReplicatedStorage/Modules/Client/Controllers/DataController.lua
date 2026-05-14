--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Data = require(Shared.Types.Data)
local Fetcher = require(Client.Libraries.Fetcher)
local Settings = require(Client.Packages.Settings)
local DataConverter = require(Client.Libraries.DataConverter)

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local CharacterDatabase = require(Shared.Database.Characters)
local ArtifactDatabase = require(Shared.Database.Artifacts)
local DrivesDatabase = require(Shared.Database.Drives)
local ItemsDatabase = require(Shared.Database.Items)
local DriveTraits = require(Shared.Database.DriveTraits)

local LocalData = require(Client.Libraries.LocalData)
local SharedData = require(Client.Libraries.SharedData)
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local function BufferTableToArtifact(Table: {})
    local Id, BufferObj = Table[1] :: string, Table[2] :: buffer
    local Equipped = buffer.readu8(BufferObj, 4)

    local MainStatKey = GameEnum.KeyLookup(GameEnum.MainStats, buffer.readu8(BufferObj, 5))
    local MainStatValue = buffer.readu8(BufferObj, 6)

    local ArtifactData: Types.PlayerArtifactData = {
        Id = Id,
        Name = ArtifactDatabase:GetFromId(buffer.readu8(BufferObj, 0)),
        Level = buffer.readu8(BufferObj, 1),
        Slot = buffer.readu8(BufferObj, 2),
        Tier = buffer.readu8(BufferObj, 3),
        Equipped = if Equipped == 0 then nil else CharacterDatabase:GetCharacterFromId(Equipped),
        Stats = {
            Main_Stat = {[MainStatKey] = MainStatValue},
            Sub_Stats = {},
        },
    }

    -- edit the substats
    local SubStats = {}
    for i = 7, 13, 2 do
        local Key = buffer.readu8(BufferObj, i)
        local Count = buffer.readu8(BufferObj, i + 1)
        local SubStatName = GameEnum.KeyLookup(GameEnum.SubStats, Key)

        -- Means there's no more substats
        if SubStatName == nil then
            break
        end

        SubStats[SubStatName] = Count
    end

    ArtifactData.Stats.Sub_Stats = SubStats

    return ArtifactData
end

local function BufferTableToDrive(Table: {}): Types.PlayerDriveData
    local Id, BufferObj = Table[1] :: string, Table[2] :: buffer

    local DriveName = DrivesDatabase:GetDriveFromId(buffer.readu8(BufferObj, 0))
    local Trait = DriveTraits:GetTraitById(buffer.readu8(BufferObj, 2))
    local EquippedId = buffer.readu8(BufferObj, 3)

    local DriveData: Types.PlayerDriveData = {
        Id = Id,
        Name = DriveName,
        Trait = Trait,
        Equipped = if EquippedId == 0 then nil else CharacterDatabase:GetCharacterFromId(EquippedId),
        Experience = buffer.readu16(BufferObj, 4),
        Level = buffer.readu8(BufferObj, 1)
    }

    return DriveData
end

local function DecompressTableOfAgents(Table: {}): {}
    local TranslatedData = {}
    for _, AgentData in Table do
        table.insert(TranslatedData, Fetcher:BufferListToData(AgentData))
    end

    return TranslatedData :: {}
end

--
local Controller = {}

function Controller:Init()
    Network:On("ItemData", function(Type: number, Payload: {}): ()
        if Type == GameEnum.ItemDataEvent.GetAllArtifacts then
            Controller:ConvertArtifacts(Payload)
        elseif Type == GameEnum.ItemDataEvent.GetAllDrives then
            Controller:ConvertDrives(Payload)
        elseif Type == GameEnum.ItemDataEvent.GetAllItems then
            Controller:ConvertItems(Payload)
        elseif Type == GameEnum.ItemDataEvent.GetCurrencies then
            Controller:ShowCurrencies(Payload)
        end
    end)

    Network:On("UpdateAgent", function(Type: number, Payload: {}): ()
        if Type == GameEnum.BuildEvent.UpdateArtifactSlot then
            Controller:UpdateArtifactState(Payload)
        elseif Type == GameEnum.BuildEvent.UpdateDrive then
            Controller:UpdateDriveState(Payload)
        elseif Type == GameEnum.BuildEvent.UpgradeAgentSkill then
            Controller:UpdateAgentSkills(Payload)
        elseif Type == GameEnum.BuildEvent.AscendAgent then
            Controller:AscendAgent(Payload)
        elseif Type == GameEnum.BuildEvent.LevelAgent then
            Controller:LevelAgent(Payload)
        elseif Type == GameEnum.BuildEvent.LevelCompanion then
            Controller:LevelCompanion(Payload)
        end
    end)

    Network:On("PlayerSettings", function(Data: {})        
        Settings:Set(Data)

        local InMatchComponent = InterfaceController:GetComponent("IngameMenu");
        if InMatchComponent then
            InMatchComponent:Refresh();
        end

        local InLobbyComponent = InterfaceController:GetComponent("Settings");
        if InLobbyComponent then
            InLobbyComponent:Refresh();
        end
    end)

    Network:On("SharedData", function(Player: Player, Data: {})
        local Agents = Data[1]
        local Drives = Data[2]
        local Artifacts = Data[3]

        local Match_Drives = {}

        for _, Drive in Drives do
            local DriveObjectData = BufferTableToDrive(Drive)

            -- Save to the full list
            table.insert(Match_Drives, DriveObjectData)
        end

        local Match_Artifacts = {}

        for _, Artifact in Artifacts do
            local ArtifactObjectData = BufferTableToArtifact(Artifact)

            -- Save to the full list
            table.insert(Match_Artifacts, ArtifactObjectData)
        end

        local Match_Agents = DecompressTableOfAgents(Agents)

        SharedData:SetData(Player, Match_Agents, Match_Drives, Match_Artifacts)

        --
        Network:Fire("SharedData")
    end)
end

function Controller:LevelAgent(Payload: {})
    local AgentData = LocalData:GetAgent(Payload[1])
    AgentData.Level = Payload[2]
    AgentData.Experience = Payload[3]

    --print('New Agent level:', AgentData.Level, AgentData.Experience)

    --
    local UI = InterfaceController:GetComponent("Agents")
    UI:RefreshInformation()
end

function Controller:AscendAgent(Payload: {})
    local AgentData = LocalData:GetAgent(Payload[1])
    AgentData.Ascensions = Payload[2]

    local UI = InterfaceController:GetComponent("Agents")

    UI:RefreshAscensions()
end

function Controller:ConvertItems(Payload: {})
    local Items = {}

    for _, ItemBuffer in Payload do
        local Id = buffer.readu16(ItemBuffer, 0)
        local Amount = buffer.readf32(ItemBuffer, 2)
        local RealName = nil
        if buffer.len(ItemBuffer) > 6 then
            RealName = buffer.readstring(ItemBuffer, 6, buffer.len(ItemBuffer) - 6)
        end

        local Name = RealName or ItemsDatabase:GetFromId(Id)
        table.insert(Items, {
            Name = Name,
            Amount = Amount,
        } :: Data.PlayerItemData)
    end

    LocalData:SetItems(Items)
end

function Controller:UpdateAgentSkills(Payload: {})
    local AgentName = Payload[1]
    local Skills = Payload[2]
    local UI = InterfaceController:GetComponent("Agents")

    local Agent = LocalData:GetAgent(AgentName)
    Agent.Skills = Skills

    UI:RefreshSkills()
end

function Controller:UpdateArtifactState(Payload: {number | {}})
    local UI = InterfaceController:GetComponent("Agents")
    local Type = Payload[1]
    local Artifact = BufferTableToArtifact(Payload[2] :: {})
    local Agent = Payload[3]
    local AgentArtifacts = Payload[4]

    LocalData:EditArtifact(Artifact)
    UI:UpdateArtifact(Artifact)
    UI:RefreshArtifactInfo(Artifact.Id)

    if Type == GameEnum.ChangeEvents.Update then
        return
    end

    LocalData:EditAgentArtifacts(Agent, AgentArtifacts)

    --
    if Type == GameEnum.ChangeEvents.Remove then
        UI:UpdateSlotInfo(Agent, Artifact.Slot, nil)

        return
    end

    UI:UpdateSlotInfo(Agent, Artifact.Slot, Artifact.Id)
end

function Controller:UpdateDriveState(Payload: {number | {}})
    local UI = InterfaceController:GetComponent("Agents")

    local Type = Payload[1]
    local Drive = BufferTableToDrive(Payload[2] :: {})
    local Agent = Payload[3]

    LocalData:EditDrive(Drive)
    UI:UpdateDrive(Drive)
    UI:RefreshDriveInfo(Drive.Id)

    if Type == GameEnum.ChangeEvents.Update then
        return
    end

    LocalData:EditAgentDrive(Agent, Drive)

    --
    if Type == GameEnum.ChangeEvents.Remove then
        UI:UpdateDriveInfo(Agent, nil)

        return
    end

    UI:UpdateDriveInfo(Agent, Drive)
end

function Controller:ConvertArtifacts(Payload: {})
    local AllArtifacts = {}

    for _, Artifact in Payload do
        local ArtifactObjectData = BufferTableToArtifact(Artifact)

        -- Save to the full list
        table.insert(AllArtifacts, ArtifactObjectData)
    end

    LocalData:SetArtifacts(AllArtifacts)
end


function Controller:ConvertDrives(Payload: {})
    local AllDrives = {}

    for _, Drive in Payload do
        local DriveObjectData = BufferTableToDrive(Drive)

        -- Save to the full list
        table.insert(AllDrives, DriveObjectData)
    end

    LocalData:SetDrives(AllDrives)
end

function Controller:ShowCurrencies(Payload: {[string]: number})
    local UIComponent = InterfaceController:GetComponent("LobbyMain")

    LocalData:SetCurrencies(Payload)

    if not UIComponent then
        return
    end

    UIComponent:ShowCurrency('Money', Payload.Money)
    UIComponent:ShowCurrency('Gems', Payload.Gems)
end

function Controller:LevelCompanion(Payload: {})
    local NewDecompressedData = DataConverter.FromCompanionCompressedObject(Payload)

    LocalData:EditCompanion(NewDecompressedData)

    --
    local UIComponent = InterfaceController:GetComponent("Companions")
    UIComponent:Refresh()
end

return Controller