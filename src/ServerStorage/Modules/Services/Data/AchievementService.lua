local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Network = require(ReplicatedStorage.Modules.Shared.Network)
local Achievements = require(Database.Achievements)
local DataService = require(script.Parent.DataService)

local Service = {}

function Service:Init()
    Network.new("Achievements", 'Event')
end

function Service:Give(Player: Player, Achievement: string)
    local PlayerData = DataService:GetDataFor(Player)
    if not PlayerData then
        return
    end

    local AchievementData = Achievements.List[Achievement]
    if AchievementData and not (PlayerData.Achievements[Achievement] == true) then
        print(Player.Name, ' has obtained achievement: ', Achievement)

        PlayerData.Achievements[Achievement] = true

        for RewardName, RewardValue in AchievementData.Rewards do
            local CurrentValue = DataService:Get(Player, RewardName)

            DataService:Set(Player, RewardName, CurrentValue + RewardValue)
        end
    end
end

return Service