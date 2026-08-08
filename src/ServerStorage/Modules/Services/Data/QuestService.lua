local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--
local Packages = ServerStorage.Modules.Packages
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Quests = require(Packages.Quests)
local Network = require(ReplicatedStorage.Modules.Shared.Network)


type UnixDate = {
    Day: number,
    Month: number,
    Year: number,
    Minute: number,
    Hour: number,
    Second: number
}

local Service = {}

function Service:Init()
    local Day_Unix = DateTime.now().UnixTimestampMillis

	RunService.Heartbeat:Connect(function(Delta)
		local StartDay = (DateTime.fromUnixTimestampMillis(Day_Unix):ToUniversalTime() :: UnixDate).Day
		local CurrentDay = (DateTime.now():ToUniversalTime() ::UnixDate).Day

		if CurrentDay ~= StartDay then
			Day_Unix = DateTime.now().UnixTimestampMillis
			
			Service:RefreshAllDailies()
		end
	end)


	--
	Network.new("Quests", 'Event')
	Network:On("Quests", function(Player: Player, Type: number, Data: {[string | number]: any})  
		if Type == GameEnum.Quests.Claim then
			local ToClaimId = Data.Id;

			if false then
				return;
			end

			local QuestObject = Quests:GetQuestById(Player, Type, ToClaimId)
			
			Service:ClaimQuest(Player, QuestObject)
		end
	end)
end

function Service:ClaimQuest(Player: Player, Quest: Quests.QuestObject)
	if not Quest or Quest.Claimed then
		return;
	end
	
	
end

function Service:RefreshDailies(Player: Player)
	Quests:RefreshDailies(Player)
end

function Service:RefreshAllDailies()
	for _, Player in Players:GetPlayers() do
		Quests:RefreshDailies(Player)
	end
end

function Service:GetPlayerQuestsWithGoals(Player: Player, GoalKeys: Quests.GoalsListType): {[string]: {Quests.QuestObject}}
	local Data = Quests:GetAllQuestsWithGoals(Player, GoalKeys)

	return Data
end

return Service