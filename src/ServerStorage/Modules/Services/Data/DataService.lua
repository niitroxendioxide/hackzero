--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage.Modules
local Packages = Modules.Packages
local Classes = Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Network = require(Shared.Network)

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)
local Clock = require(Shared.Utility.Clock)

local ProfileTemplate = require(Database.Data.ProfileTemplate)
local CharacterDatabase = require(Database.Characters)

local PlayerAgentDataClass = require(Classes.Data.PlayerAgentData)

local ProfileStore = require(Packages.Data.ProfileStore)
local DataStore = ProfileStore.New("Testing0", ProfileTemplate)


--
local Service = {
    __Profiles = {} :: {[Player]: typeof(ProfileStore:StartSessionAsync())},
    __Agents = {},
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

    Network.new("DataFetchRequest", "Event")
    Network:On("DataFetchRequest", function(Player: Player, Type: string)
        local _PlayerData = Service:GetDataFor(Player)

        if Type == GameEnum.FetchRequests.Agents then
            local Agents = Service:FetchAgents(Player)

            Network:Fire("DataFetchRequest", Player, GameEnum.FetchRequests.Agents, Agents)
        end
    end)
end

function Service:FetchAgents(Player: Player)
    local Agents = Service:GetPlayerAgents(Player)

    local Data = {}
    for _, Agent in Agents do
        table.insert(Data, Agent:Compress())
    end

    return Data
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
            Service:SavePlayerAgentData(Player)
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
        else
        -- The player has left before the profile session started
            RetrievedProfile:EndSession()
        end
    else
        Player:Kick(`Profile load fail - Please rejoin`)
    end
end

function Service:RemovePlayer(Player: Player)
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

    if typeof(Value) ~= Dir[Key] then
        return warn("Invalid type given for key:", GivenKey, `value expected: {typeof(Dir[Key])}, given: {typeof(Value)}`)
    end

    Dir[Key] = Value

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

function Service:AddAgent(Player: Player, Agent: Types.PlayerAgentDataClass)
    local PlayerData = Service:GetDataFor(Player)

    for AgentName in PlayerData.Agents do
        if AgentName == Agent.Name then
            return
        end
    end

    PlayerData.Agents[Agent.Name] = Agent:ToData()
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

function Service:CreateAgentClass(Player: Player, Name: string)
    local PlayerData = Service:GetDataFor(Player)
    local AgentData = PlayerData.Agents[Name] or {}

    if Service.__Agents[Player] == nil then
        Service.__Agents[Player] = {}
    end

    if Service.__Agents[Player][Name] == nil then
        local Now = DateTime.now().UnixTimestamp
        local ClassObject = PlayerAgentDataClass.new(Name, AgentData.Level or 1, AgentData.Obtained or Now)

        if (AgentData.Weapon and AgentData.Weapon.Name ~= nil) then
            ClassObject:SetWeapon(AgentData.Weapon.Name, AgentData.Weapon.Level)
        end

        if AgentData.Artifacts then
            ClassObject:SetArtifacts(AgentData.Artifacts)
        end

        Service.__Agents[Player][Name] = ClassObject
    end
end

function Service:GetAgent(Player: Player, Name: string)
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

function Service:SavePlayerAgentData(Player: Player)
    for _, Agent: Types.PlayerAgentDataClass in (Service.__Agents[Player] or {}) do
        Service:UpdateAgent(Player, Agent)
    end
end

function Service:UnlockAllAgents(Player: Player)
    local Characters = CharacterDatabase:GetAllCharacterNames()
	for _, CharacterName in Characters do
		local Agent = PlayerAgentDataClass.new(CharacterName, 1, DateTime.now().UnixTimestamp)

		Service:AddAgent(Player, Agent)
	end
end

return Service
