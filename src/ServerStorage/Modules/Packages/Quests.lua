local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Services = ServerStorage.Modules.Services
local Database = Shared.Database

local DataService = require(Services.Data.DataService)
local QuestsDatabase = require(Database.Quests)

--
export type GoalsListType = {[string]: true}
export type QuestType = "Daily" | "Main" | "Interactions" | "World"
export type RewardList = {[string]: number}
export type QuestObject = {
    Created: number,
    Id: string,
    Name: string,
    Type: QuestType,
    Claimed: boolean,

    Description: string,
    Goals: {
        [string]: {[string]: number} | number,
    },

    Progress: {
        [string]: {[string]: number} | number,
    },

    Rewards: {
        Currency: RewardList,
        Items: RewardList,
        Player_Experience: number?,   
    }
}

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
local DailyNames = {"DailyEnemies", "DailyStructures", "DailyInteractions"}
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
        Type = Type,
        Claimed = false,
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

function Quests:GetQuestById(Player: Player, QuestType: string?, QuestId: string): QuestObject?
    local PlayerData = DataService:GetDataFor(Player)
    local Directory = PlayerData.Quests[QuestType or 'Daily']

    if not Directory then
        return
    end

    for _, Quest in Directory do
        if Quest.Id == QuestId then
            return Quest
        end
    end

    return;

end

function Quests:GetAllQuestsOfType(Player: Player, Type: QuestType): {QuestObject}
    if not Type then return {} end

    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData or not PlayerData.Quests then
        return {}
    end
    local Directory = PlayerData.Quests[Type]

    return Directory
end

function Quests:GetAllQuests(Player: Player): {QuestObject}
    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData or not PlayerData.Quests then
        return {}
    end

    local Total = {}
    for _, QuestDir in PlayerData.Quests do
        for _, Quest in QuestDir do
            table.insert(Total, Quest)
        end
    end

    return Total
end

function Quests:GetAllQuestsWithGoals(Player: Player, Goals: GoalsListType): {[string]: {QuestObject}}
    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData or not PlayerData.Quests then
        return {}
    end

    local Total = {}
    for _, QuestDir in PlayerData.Quests do
        for _, Quest: QuestObject in QuestDir do
            for Goal in Quest.Goals do
                if Goals[Goal] == true then
                    if Total[Goal] == nil then
                        Total[Goal] = {}
                    end

                    table.insert(Total[Goal], Quest)
                end
            end
        end
    end

    return Total
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