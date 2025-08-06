--[[ 
	2025 @niitroxendioxide
--]]

--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local AgentDatabase = require(Database.Characters)
local CompanionsDatabase = require(Database.Companions)

local ClockUtil = require(Shared.Utility.Clock)
local SyncedTime = require(script.Parent.SyncedTime)
local Network = require(Shared.Network)

-- 	CONSTANTS
local REFRESHTIME = 1
local DAYTIME = 86400 * (REFRESHTIME/24) -- (1/24 is one hour)


-- Private func
local function ShallowCopy(original)
	local copy = {}
	for k, v in original do
		copy[k] = v
	end

	return copy
end

local function ToHMS(Seconds: number)
	return string.format("%02i:%02i:%02i", Seconds/60^2, Seconds/60%60, Seconds%60)
end

--
local System = {
	CurrentDay = nil,
	MaxTimeoutAttempts = 5,
	HourOffset = 0,
	RefreshTime = REFRESHTIME, -- HOURS

	__CurrentBanner = {},
	__RarityUnits = {},
	__Random = nil :: Random?,
}

function System:Init()
	Network.new("Banner", "Event")

	SyncedTime.Init()
    System:CreatePool()

    -- // Init main loop
    local Offset = 3600 * System.HourOffset;
	ClockUtil:ThreadLoop(1, function()

		local Day = math.floor((SyncedTime.time() + Offset) / (60 * 60 * System.RefreshTime));

        local OffsetTime = (math.floor(SyncedTime.time())) - Offset;
        local DayProgress = OffsetTime % DAYTIME;
        local TimeLeft = DAYTIME - DayProgress;

        workspace:SetAttribute('BannerTimeLeft', ToHMS(TimeLeft));

        if Day ~= System.CurrentDay then
            System.CurrentDay = Day

            System:GenerateRandomBanner({
                --'Mythical',
                --'Legendary',
				'Mythical',
                'Legendary',
				'Rare',
				'Rare',
				'Rare',
            })

            --print("Update banner", System:GetBanner())
            Network:FireForAll("Banner", System:GetBanner())
        end
	end)
end

function System:GetBanner(): {[number]: string}
	return System.__CurrentBanner
end

function System:GetCharacterFromBannerWithRarity(Rarity: string): (string?)
	local Banner = System:GetBanner()
	local Choices = {}

	for _, Character in Banner do
		if Character[2] == Rarity then
			table.insert(Choices, Character[1])
		end
	end

	if #Choices == 0 then
		return;
	end

	return Choices[math.random(1, #Choices)]
end

function System:CreatePool()
    for _, Unit in AgentDatabase:GetAllCharacterNames() do
		local Data = AgentDatabase:GetCharacterData(Unit)
        local Rarity = Data.Tier

		if Data.NotOnBanner then continue end

		if not(System.__RarityUnits[Rarity]) then
			System.__RarityUnits[Rarity] = {}
		end

		table.insert(System.__RarityUnits[Rarity], Unit)
	end

	for _, Unit in CompanionsDatabase:GetAllNames() do
		local Data = CompanionsDatabase:GetCompanionData(Unit)
        local Rarity = Data.Tier

		if Data.NotOnBanner then continue end

		if not(System.__RarityUnits[Rarity]) then
			System.__RarityUnits[Rarity] = {}
		end

		table.insert(System.__RarityUnits[Rarity], Unit)
	end
end

function System:GenerateRandomBanner(Rarities: {string | {string}})
	System.__Random = Random.new(System.CurrentDay);
	local Banner = {};

	local Index = 1
	local Attempts = 250
	repeat
		local GeneratedUnit = System:GenerateRandomUnit(Banner, Rarities[Index])

		if GeneratedUnit then
			Index += 1
			table.insert(Banner, GeneratedUnit);
		end

		Attempts-=1
	until #Banner >= #Rarities or Attempts <= 0;

    System.__CurrentBanner = table.freeze(Banner)

	return Banner;
end

function System:GenerateRandomUnit(Current_Table: {}, RarityID: string | {string & string})
	local Unit, Rarity = System:GetRandomUnit(RarityID);
	local RarityCopy = ShallowCopy(Rarity);

	--Duplicate check below
	for _, ExistingUnit in Current_Table do
		local Duplicate = ExistingUnit[1] == Unit

		if Duplicate then
			for idNum, CharacterName in RarityCopy do
				for i = 1, #Current_Table do
					if CharacterName == Current_Table[i][1] then
						table.remove(RarityCopy, table.find(RarityCopy, CharacterName));
					end
				end
			end

			local Attempts = System.MaxTimeoutAttempts;
			repeat
				Attempts -= 1;
				Unit = RarityCopy[System.__Random:NextInteger(1, #RarityCopy)];
			until Unit ~= Current_Table or Attempts <= 0;
		end
	end

	local RarityIDCorrect = RarityID
	if typeof(RarityID) == 'table' then
		RarityIDCorrect = RarityID[1]
	end

	local IsAgent = AgentDatabase:GetCharacterData(Unit) ~= nil


	return {Unit, RarityIDCorrect, IsAgent and 'Agent' or 'Companion'}
end

function System:GetRandomUnit(Rarity: string | {string & string})
	local RarityId = Rarity
	if typeof(Rarity) == 'table' then
		RarityId = Rarity[1]
	end

	local Dict = System.__RarityUnits[RarityId]
	if not Dict then return end

	local RandomPos = System.__Random:NextInteger(1, #Dict)
	if typeof(Rarity) == 'table' then
		Dict = {Rarity[2]}
		RandomPos = 1
	end

	return Dict[RandomPos], Dict
end

return System
