--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Packages = Modules.Packages
local Classes = Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local QuestUtil = require(ServerStorage.Modules.Libraries.QuestUtil)
local Agent = require(ReplicatedStorage.Modules.Client.Classes.Agent)
local Network = require(Shared.Network)
local DataTypes = require(Shared.Types.Data)

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)
local Clock = require(Shared.Utility.Clock)

local ProfileTemplate = require(Database.Data.ProfileTemplate)
local CharacterDatabase = require(Database.Characters)

local PlayerItemDataClass = require(Classes.Data.PlayerItemData)
local PlayerAgentDataClass = require(Classes.Data.PlayerAgentData)
local PlayerDriveDataClass = require(Classes.Data.PlayerDriveData)
local PlayerArtifactDataClass = require(Classes.Data.PlayerArtifactData)

local ProfileStore = require(Packages.Data.ProfileStore)
local DataStore = ProfileStore.New("linganguli", ProfileTemplate)

--
local ReplicatedKeys = {"Gems", "Money"}
local Service = {
    __Profiles = {} :: {[Player]: typeof(ProfileStore:StartSessionAsync())},
    __Agents = {},
    __Artifacts = {},
    __Drives = {},
    __Items = {},

}

local function RecursiveSearch(Data: {}, Key: string): ({}, string)
    local Split = string.split(Key, "/")
    local End = Data;
    local FinalKey = Split[#Split];

    for Key = 1, #Split - 1 do
        local RealKey = Split[Key]

        if End[RealKey] == nil then break end

        End = End[RealKey]
    end

    return End, FinalKey
end

function Service:Init()
    Network.new('ItemData', 'Event')
    Network.new("DataFetchRequest", "Event")

    -- Binding
    Network:On("DataFetchRequest", function(Player: Player, Type: string)
        local _PlayerData = Service:GetDataFor(Player)

        if Type == GameEnum.FetchRequests.Agents then
            local Agents = Service:FetchAgents(Player)

            Network:Fire("DataFetchRequest", Player, GameEnum.FetchRequests.Agents, Agents)
        elseif Type == GameEnum.FetchRequests.Quests then
            local Quests = {}
            local PlayerData = Service:GetDataFor(Player)
            for _, QuestDir in PlayerData.Quests do
                for _, Quest in QuestDir do
                    table.insert(Quests, QuestUtil:Compress(Quest))
                end
            end

            Network:Fire("DataFetchRequest", Player, GameEnum.FetchRequests.Quests, Quests)
        end
    end)

    Network:On("ItemData", function(Player: Player, Type: number)
        if Type == GameEnum.ItemDataEvent.GetAllArtifacts then
            Service:UpdatePlayerArtifacts(Player)
        elseif Type == GameEnum.ItemDataEvent.GetAllDrives then
            Service:UpdatePlayerDrives(Player)
        elseif Type == GameEnum.ItemDataEvent.GetCurrencies then
            --
        end
    end)
end

function Service:FetchAgents(Player: Player)
    local Agents = Service:GetPlayerAgents(Player)

    local Data = {}
    for _, Agent in (Agents or {}) do
        table.insert(Data, Agent:Compress())
    end

    return Data
end

function Service:FetchItems(Player: Player)
    local Items = Service:GetItems(Player)

    local Data = {}
    for _, Item in (Items or {}) do
        if Item.__Amount > 0 then
            table.insert(Data, Item:Compress())
        end
    end

    return Data
end

function Service:ConstructAgentDataClass(GivenData: {Name: string, Level: number, Drive: string?, Artifacts: {}?, Skills: {}?, Ascensions: {}?})
    local Now = DateTime.now().UnixTimestamp
    local ClassObject = PlayerAgentDataClass.new(GivenData.Name, GivenData.Level, Now)

    if GivenData.Drive then
        ClassObject:SetDrive(GivenData.Drive)
    end

    if GivenData.Artifacts then
        ClassObject:SetArtifacts(GivenData.Artifacts)
    end

    if GivenData.Skills then
        for SkillName, SkillLevel in GivenData.Skills do
            ClassObject:SetSkill(SkillName, SkillLevel)
        end
    end

    if GivenData.Ascensions then
        ClassObject:SetAscensions(GivenData.Ascensions)
    end

    return ClassObject
end

function Service:FetchArtifacts(Player: Player, Filter: ((a: Types.PlayerArtifactDataClass) -> (boolean))?)
    local Artifacts = Service:GetArtifacts(Player, Filter)
    if not Artifacts then return end
    local Data = {}

    if Artifacts.__Id then
        Artifacts = {Artifacts}
    end

    for _, Artifact in Artifacts do
        local CompressedObject = Artifact:Compress()

        table.insert(Data, CompressedObject)
    end

    return Data
end

function Service:FetchDrives(Player: Player, Filter: ((a: Types.PlayerDriveDataClass) -> (boolean))?)
    local Drives = Service:GetDrives(Player, Filter)
    if not Drives then return end
    local Data = {}

    if Drives.__Id then
        Drives = {Drives}
    end

    for _, Drive in Drives do
        local CompressedObject = Drive:Compress()

        table.insert(Data, CompressedObject)
    end

    return Data
end

function Service:UpdatePlayerArtifacts(Player: Player): ()
    local Artifacts = Service:FetchArtifacts(Player)
    if not Artifacts then return end

    Network:Fire("ItemData", Player, GameEnum.ItemDataEvent.GetAllArtifacts, Artifacts)
end

function Service:UpdatePlayerDrives(Player: Player): ()
    local Drives = Service:FetchDrives(Player)
    if not Drives then return end

    Network:Fire("ItemData", Player, GameEnum.ItemDataEvent.GetAllDrives, Drives)
end

function Service:UpdatePlayerItems(Player: Player): ()
    local Items = Service:FetchItems(Player)
    if not Items then return end

    Network:Fire("ItemData", Player, GameEnum.ItemDataEvent.GetAllItems, Items)
end

function Service:SyncPlayerItems(Player: Player)
    local Data = Service:GetDataFor(Player)

    Service:UpdatePlayerArtifacts(Player)
    Service:UpdatePlayerDrives(Player)
    Service:UpdatePlayerItems(Player)

    Network:Fire('ItemData', Player, GameEnum.ItemDataEvent.GetCurrencies, {
        ['Money'] = Data.Money,
        ['Gems'] = Data.Gems,
    })
end


function Service:AddPlayer(Player: Player)
    local RetrievedProfile = DataStore:StartSessionAsync(`{Player.UserId}`, {
        Cancel = function()
            return Player.Parent ~= Players
        end,
    })

    -- Handling new profile session or failure to start it:

    if RetrievedProfile ~= nil then
        RetrievedProfile:AddUserId(Player.UserId)
        RetrievedProfile:Reconcile()

        local Thread = Clock:ThreadLoop(300, function()
            Service:SavePlayerData(Player)
        end)

        RetrievedProfile.OnSessionEnd:Connect(function()
            Service.__Profiles[Player] = nil
            Player:Kick(`Profile session ended. Rejoin (Data disconnected)`)

            if Thread then
                task.cancel(Thread)
            end
        end)

        if Player.Parent == Players then
            Service.__Profiles[Player] = RetrievedProfile

            Service:SetupAgents(Player)
            Service:SetupArtifacts(Player)
            Service:SetupDrives(Player)
            Service:SetupItems(Player)
        else
        -- The player has left before the profile session started
            RetrievedProfile:EndSession()
        end
    else
        Player:Kick(`Profile load fail - Please rejoin`)
    end
end

function Service:RemovePlayer(Player: Player): ()

    -- Save the latest info about the agents
    Service:SavePlayerData(Player)

    --
    local SavedProfile = Service.__Profiles[Player]
    if SavedProfile ~= nil then
        SavedProfile:EndSession()
    end

    if Service.__Agents[Player] then
        Service.__Agents[Player] = nil
    end
end

function Service:GetDataFor(Player: Player): Types.PlayerProfileData
    local Data = Service.__Profiles[Player]
    if Data == nil then
        return {} :: Types.PlayerProfileData;
    end

    return Data.Data
end

function Service:Set(Player: Player, GivenKey: string, Value: any)
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    if typeof(Value) ~= typeof(Dir[Key]) then
        return warn("Invalid type given for key:", GivenKey, `value expected: {typeof(Dir[Key])}, given: {typeof(Value)}`)
    end

    Dir[Key] = Value

    --

    if table.find(ReplicatedKeys, Key) then
        Network:Fire('ItemData', Player, GameEnum.ItemDataEvent.GetCurrencies, {
            ['Money'] = Data.Money,
            ['Gems'] = Data.Gems,
        })
    end

    --

    return;
end

function Service:Get(Player: Player, GivenKey: string)
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    return Dir[Key]
end

function Service:Add(Player: Player, GivenKey: string, Object: {}): ()
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    if typeof(Dir[Key]) ~= "table" then
        return warn(`Cannot add object to table because directory {GivenKey} is not a table`)
    end

    table.insert(Dir[Key], Object)

    return;
end

function Service:Increase(Player, GivenKey: string, Value: number)
    local Data = Service:GetDataFor(Player)
    local Dir, Key = RecursiveSearch(Data, GivenKey)

    if typeof(Dir[Key]) ~= "number" then
        return warn(`Cannot edit value {GivenKey} because it is not a number [{Dir}, {Key}]`)
    end

    Dir[Key] = Dir[Key] + Value

    if table.find(ReplicatedKeys, Key) then
        Network:Fire('ItemData', Player, GameEnum.ItemDataEvent.GetCurrencies, {
            ['Money'] = Data.Money,
            ['Gems'] = Data.Gems,
        })
    end

    return
end

function Service:AddAgent(Player: Player, Agent: Types.PlayerAgentDataClass)
    local PlayerData = Service:GetDataFor(Player)

    if Service:HasAgent(Player, Agent.Name) then
        return Service:CreateAgentClass(Player, Agent.Name)
    end

    PlayerData.Agents[Agent.Name] = Agent:ToData()
    Service:SetAgentClass(Player, Agent)

    return
end

function Service:HasAgent(Player: Player, AgentName: string): (boolean)
    local PlayerData = Service:GetDataFor(Player)


    for PlayerOwnedAgentName in PlayerData.Agents do
        if PlayerOwnedAgentName == AgentName then
            return true
        end
    end

    return false
end

function Service:UpdateAgent(Player: Player, Agent: Types.PlayerAgentDataClass)
    local PlayerData = Service:GetDataFor(Player)

    if PlayerData.Agents[Agent.Name] == nil then
        return
    end

    PlayerData.Agents[Agent.Name] = Agent:ToData()
end

function Service:SetupAgents(Player: Player)
    local PlayerData = Service:GetDataFor(Player)

    for Agent, Data in PlayerData.Agents do
        Service:CreateAgentClass(Player, Agent)
    end
end

function Service:SetupArtifacts(Player: Player): ()
    local PlayerData = Service:GetDataFor(Player)

    for Id, Artifact in PlayerData.Items.Artifacts do
        local Agent = Artifact.Equipped

        if Agent then
            Agent = Service:GetAgent(Player, Agent)
        end

        local Class = PlayerArtifactDataClass.new(Artifact, Agent)
        Service:AddArtifact(Player, Class)
    end
end

function Service:SetAgentClass(Player: Player, AgentClass: Types.PlayerAgentDataClass): ()
    if Service.__Agents[Player] == nil then
        Service.__Agents[Player] = {}
    end

    if not AgentClass.Name then
        return
    end

    Service.__Agents[Player][AgentClass.Name] = AgentClass
end

function Service:CreateAgentClass(Player: Player, Name: string)
    local PlayerData = Service:GetDataFor(Player)
    local AgentData = PlayerData.Agents[Name]

    if not AgentData then
        return
    end

    if Service.__Agents[Player] == nil then
        Service.__Agents[Player] = {}
    end

    if Service.__Agents[Player][Name] == nil then
        local Now = DateTime.now().UnixTimestamp
        local ClassObject = PlayerAgentDataClass.new(Name, AgentData.Level or 1, AgentData.Obtained or Now)

        if AgentData.Drive then
            ClassObject:SetDrive(AgentData.Drive)
        end

        if AgentData.Artifacts then
            ClassObject:SetArtifacts(AgentData.Artifacts)
        end

        if AgentData.Skills then
            for SkillName, SkillLevel in AgentData.Skills do
                ClassObject:SetSkill(SkillName, SkillLevel)
            end
        end

        if AgentData.Ascensions then
            ClassObject:SetAscensions(AgentData.Ascensions)
        end

        if AgentData.Experience then
            ClassObject.Experience = AgentData.Experience
        end

        Service:SetAgentClass(Player, ClassObject)
    end
end

function Service:GetAgent(Player: Player, Name: string, CreateIfDoesntExist: boolean?)
    if not Service.__Agents[Player] then
        Service.__Agents[Player] = {}
    end

    if Service.__Agents[Player][Name] == nil then
        Service:CreateAgentClass(Player, Name)
    end

    return Service.__Agents[Player][Name]
end

function Service:GetPlayerAgents(Player: Player): {[string]: Types.PlayerAgentDataClass}
    return Service.__Agents[Player]
end

function Service:SavePlayerData(Player: Player)
    for _, Agent: Types.PlayerAgentDataClass in (Service.__Agents[Player] or {}) do
        Service:UpdateAgent(Player, Agent)
    end

    for _, Drive: Types.PlayerDriveDataClass in (Service.__Drives[Player] or {}) do
        Service:AddDrive(Player, Drive)
    end

    for _, Artifact: Types.PlayerArtifactDataClass in (Service.__Artifacts[Player] or {}) do
        Service:AddArtifact(Player, Artifact)
    end

    for _, Item: DataTypes.PlayerItemDataClass in (Service.__Items[Player] or {}) do
        Service:SaveItem(Player, Item)
    end
end

function Service:AddArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass): ()
    local PlayerData = Service:GetDataFor(Player)
    local ArtifactData = Artifact:ToData()

    if Service.__Artifacts[Player] == nil then
        Service.__Artifacts[Player] = {}
    end

    PlayerData.Items.Artifacts[Artifact.__Id] = ArtifactData
    Service.__Artifacts[Player][Artifact.__Id] = Artifact
end

--[[
    Returns a list if the amount of items is >1, else it returns a singular one.

    @param Player The player whose artifacts need to be accessed
    @param Filter The filter used to get specific artifacts
]]
function Service:GetArtifacts<T>(Player: Player, Filter: ((Artifact: Types.PlayerArtifactDataClass) -> (boolean))?, First: boolean?): {Types.PlayerArtifactDataClass}
    local Artifacts = {}

    if Filter == nil then
        return Service.__Artifacts[Player]
    end

    for _, Artifact in (Service.__Artifacts[Player] or {}) do
        if (#Artifacts == 1 and (First == true)) then
            break
        end

        if Filter(Artifact) then
            table.insert(Artifacts, Artifact)
        end
    end

    if #Artifacts == 1 then
        return Artifacts[1]
    end

    --
    return Artifacts
end

---
function Service:GetDrives<T>(Player: Player, Filter: ((Drive: Types.PlayerDriveDataClass) -> (boolean))?, First: boolean?): T | {Types.PlayerDriveDataClass}
    local Drives = {}
    if not Service.__Drives[Player] then
        return Drives;
    end

    if Filter == nil then
        return Service.__Drives[Player]
    end

    for _, Drive in (Service.__Drives[Player] or {}) do
        if (#Drives == 1 and (First == true)) then
            break
        end

        if Filter(Drive) then
            table.insert(Drives, Drive)
        end
    end

    if #Drives == 1 then
        return Drives[1]
    end

    return Drives
end

function Service:AddDrive(Player: Player, Drive: Types.PlayerDriveDataClass)
    local PlayerData = Service:GetDataFor(Player)

    if Service.__Drives[Player] == nil then
        Service.__Drives[Player] = {}
    end

    Service.__Drives[Player][Drive.__Id] = Drive
    PlayerData.Items.Drives[Drive.__Id] = Drive:ToData()
end

function Service:SetupDrives(Player: Player)
    local PlayerData = Service:GetDataFor(Player)

    for _, DriveData in PlayerData.Items.Drives do
        local Agent = DriveData.Equipped
        if Agent then
            Agent = Service:GetAgent(Player, Agent)
        end

        local Drive = PlayerDriveDataClass.new(DriveData, Agent)

        Service:AddDrive(Player, Drive)
    end
end


function Service:SaveItem(Player: Player, Item: DataTypes.PlayerItemDataClass)
    local PlayerData = Service:GetDataFor(Player)
    if not Service.__Items[Player] then
        Service.__Items[Player] = {}
    end

    PlayerData.Items.Progress[Item.__Name] = Item:ToData()
    Service.__Items[Player][Item.__Name] = Item
end

function Service:GetItem(Player: Player, ItemName: string, CreateIfDoesntExist: boolean?)
    if not Service.__Items[Player] then
        Service.__Items[Player] = {}
    end

    local Item = Service.__Items[Player][ItemName]

    if CreateIfDoesntExist and Item == nil then
        local Class = PlayerItemDataClass.new(ItemName, 0)

        Service:SaveItem(Player, Class)
        Item = Class
    end

    return Item
end

function Service:GetItems(Player: Player)
    return Service.__Items[Player]
end

function Service:SetupItems(Player: Player)
    local PlayerData = Service:GetDataFor(Player)

    for _, ItemData in PlayerData.Items.Progress do
        local Class = PlayerItemDataClass.new(ItemData.Name, ItemData.Amount)

        Service:SaveItem(Player, Class)
    end
end

function Service:HasItem(Player: Player, ItemName: string, Amount: number): boolean
    local Retrieved = Service:GetItem(Player, ItemName)
    if not Retrieved then
        return false
    end

    Amount = Amount or 1

    return Amount and (Retrieved.__Amount >= Amount)
end

function Service:TakeItem(Player: Player, ItemName: string, Amount: number)
    local Retrieved = Service:GetItem(Player, ItemName)
    if not Retrieved then
        return
    end

    Retrieved:SetAmount(Retrieved.__Amount - Amount)
end


---
function Service:UnlockAllAgents(Player: Player)
    local Characters = CharacterDatabase:GetAllCharacterNames()
	for _, CharacterName in Characters do
		local Agent = PlayerAgentDataClass.new(CharacterName, 1, DateTime.now().UnixTimestamp)

		Service:AddAgent(Player, Agent)
	end
end

return Service
