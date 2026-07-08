---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Modules = ServerStorage.Modules

--- 
local Types = require(Shared.Types.Stages)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local DataService = require(Modules.Services.Data.DataService)
local MatchStats = require(Modules.Libraries.MatchStats)
local AchievementService = require(Modules.Services.Data.AchievementService)

--- Classes
local ItemClass = require(Modules.Classes.Data.PlayerItemData)
local DriveClass = require(Modules.Classes.Data.PlayerDriveData)
local ArtifactClass = require(Modules.Classes.Data.PlayerArtifactData)



---
local Rewards = {}

function Rewards:Give(Player: Player, List: {Types.LootItem})

    for _, Object in List do
        print('[SERVER] Loot:', Object.Type, Object.Amount, 'Given.', Object)
        local ObjectName = Object.Extra and Object.Extra.Name

        if Object.Type == 'Gold' or Object.Type == 'Money' then
            local Money = DataService:Get(Player, 'Money')

            DataService:Set(Player, 'Money', Money + Object.Amount)
            ---
        elseif Object.Type == 'Gems' then
            local Gems = DataService:Get(Player, 'Gems')

            DataService:Set(Player, 'Gems', Gems + Object.Amount)
            ---
        elseif Object.Type == 'Artifact' then
            local ArtifactSlot = Object.Extra.Slot or math.random(1, 6)

            local NewArtifact = ArtifactClass.randomize(ObjectName, 'Epic', 10, ArtifactSlot)
            DataService:AddArtifact(Player, NewArtifact)
            ---
        elseif Object.Type == 'Drive' then
            local NewDrive = DriveClass.randomize(ObjectName)
            DataService:AddDrive(Player, NewDrive)
            ---
        elseif Object.Type == 'Item' then
            local NewItem = ItemClass.new(ObjectName, Object.Amount)
            DataService:SaveItem(Player, NewItem)
        end
    end

end

function Rewards:CleanupRewards(Player: Types.StagePlayer, Items: {})
    for _, Item in Player:GetObtainedLoot() do
        if Item.Type == 'Gold' then
            Item.Type = 'Money'
        end
    end

    for _, Item in Player:GetObtainedLoot() do
        if (Item.Type == "Money") or Item.Type == "Gems" then
            local Found = false
            for _, ExistingItem in Items do
                if (ExistingItem.Type == Item.Type) then
                    ExistingItem.Amount += Item.Amount
                    Found = true
                end
            end

            if Found then continue end
        end

        table.insert(Items, {
            Type = Item.Type,
            Amount = Item.Amount,
            Extra = Item.Extra,
        })
    end
end

function Rewards:SpreadRewards(Players: { Types.StagePlayer }, MatchRewards: {}, MatchData: { read Rank: any, read TotalDamage: any, read WinStatus: any, read Experience: number } )
    for _, StagePlayer in Players do
        local Items = table.clone(MatchRewards)
        Rewards:CleanupRewards(StagePlayer, Items);
        Rewards:Give(StagePlayer:GetBase(), Items);

        local PlayerStats = {
            Total_Damage = MatchData.TotalDamage,
        }

        local BasePlayer: Player = StagePlayer:GetBase()
        for StatName, Value in (MatchStats:GetAllPlayerStats(BasePlayer) or {}) do
            PlayerStats[StatName] = Value
        end

        local Key = "Stats.TotalMissions"
        local TotalMissions = DataService:Get(BasePlayer, Key) or 0

        DataService:Set(BasePlayer, Key, TotalMissions + 1)
        DataService:GiveExperience(BasePlayer, MatchData.Experience)
        AchievementService:Give(BasePlayer, "Beginner_Agent")

        local PlayerEndResult = {
            Status = MatchData.WinStatus,
            Rank = MatchData.Rank,
            Experience = MatchData.Experience,
            PlayerExperience = DataService:Get(BasePlayer, "Experience"),
            PlayerLevel = DataService:Get(BasePlayer, 'Level'),
            Stage = MatchData.Stage,
            Stats = PlayerStats,

            Items = Items,
        }

        Network:Fire("Match", StagePlayer:GetBase(), GameEnum.MatchEvents.MatchEnded, PlayerEndResult)
    end
end

return Rewards