local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--
local Packages = ServerStorage.Modules.Packages
local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local Quests = require(Packages.Quests)


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

			for _, Player in Players:GetPlayers() do
				Quests:RefreshDailies(Player)
			end
		end
	end)
end

return Service