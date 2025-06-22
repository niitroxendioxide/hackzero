local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Services = ServerStorage.Modules.Services
local Database = Shared.Database

local DataService = require(Services.Data.DataService)
local QuestsDatabase = require(Database.Quests)

--
export type QuestType = "Daily" | "Main" | "Interactions" | "World"
export type QuestObject = {
    Created: number,
    Id: string,
    Name: string,

    Description: string,
    Goals: {
        [string]: {[string]: number} | number,
    },

    Progress: {
        [string]: {[string]: number} | number,
    },

    Rewards: {
        [string]: {[string]: number} | number,
    }
}

local function CompressQuest(BaseQuestName: string, QuestObj: {})
    local BaseId
end

local function CopyWithDefaultValues(Table: {})
    local NewTable = {}

    for Key in Table do
        if typeof(Table[Key]) == 'table' then
            NewTable[Key] = CopyWithDefaultValues(Table[Key])
        else
            NewTable[Key] = 0
        end
    end

    return NewTable
end

--
local DailyNames = {"DailyEnemies"}
local Quests = {}

function Quests:AddQuest(Player: Player, Type: QuestType, Data: {[string]: any})
    if not Data.Goals then
        warn("Cannot create quest with empty goals")
        return
    end

    local PlayerData = DataService:GetDataFor(Player)
    local Directory = PlayerData.Quests[Type]
    if not Directory then
        return
    end

    local QuestObject: QuestObject = {
        Created = DateTime.now().UnixTimestamp,
        Id = HttpService:GenerateGUID(false):sub(1, 7),
        Goals = Data.Goals,
        Progress = CopyWithDefaultValues(Data.Goals),
        Rewards = Data.Rewards,
        Description = Data.Description,
        Name = Data.Name or Type..'Quest',
    }

    table.insert(Directory, QuestObject)
end

function Quests:GetFirstQuestWithName(Player: Player, Type: QuestType, Name: string): (QuestObject?)
    local PlayerData = DataService:GetDataFor(Player)
    local Directory = PlayerData.Quests[Type]

    if not Directory then
        return
    end

    for _, Quest in Directory do
        if Quest.Name == Name then
            return Quest
        end
    end

    return;
end

function Quests:GetAllQuestsOfType(Player: Player, Type: QuestType): {QuestObject}
    if not Type then return {} end

    local PlayerData = DataService:GetDataFor(Player)
    local Directory = PlayerData.Quests[Type]

    return Directory
end

function Quests:RemoveQuest(Player: Player, Type: QuestType, Id: string): (boolean)
    if not Id then
        return false
    end

    local PlayerData = DataService:GetDataFor(Player)
    local Directory = PlayerData.Quests[Type]
    if not Directory then
        return false
    end

    for key, Quest in Directory do
        if Quest.Id == Id then
            table.remove(Directory, key)

            return true
        end
    end

    return false
end

function Quests:SyncPlayer(Player: Player, Type: QuestType?)

    if Type then
        
    else
        
    end

end

function Quests:RefreshDailies(Player: Player)
    local PlayerDataExists = DataService:GetDataFor(Player)
    if not PlayerDataExists then return end
    local RandomDailies = table.clone(DailyNames)

    for _, Quest in Quests:GetAllQuestsOfType(Player, "Daily") do
        Quests:RemoveQuest(Player, "Daily", Quest.Id)
    end

    for i = 1, math.min(#RandomDailies, 3) do
        local Chosen = math.random(1, #RandomDailies)
        local BaseQuest = RandomDailies[Chosen]

        local DataForBaseQuest = QuestsDatabase:GetByName(BaseQuest)

        Quests:AddQuest(Player, "Daily", DataForBaseQuest)

        table.remove(RandomDailies, Chosen)
    end

    print('Current player dailies: ', Quests:GetAllQuestsOfType(Player, "Daily"))
end

return Quests