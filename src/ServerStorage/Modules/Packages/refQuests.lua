--[[ 
	2024 @ Juaniitrox & B1gManPeter
	Anime Uprising
--]]

--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--
local Shared = ReplicatedStorage.Shared
local Database = Shared.Database
local ServerModules = ServerStorage.Server.Modules

local PremadeQuests = require(Database.PremadeQuests)

local Types = require(Shared.Types)
local DataManager = require(ServerModules.DataManager)
local UpdateQuest = require(Shared.Network.UpdateQuest):Server()

local ReverseTypeLookup = {['I'] = 'Infinite', ['M'] = 'Main', ['D'] = 'Daily', ['E'] = 'Event'}

--
local function RecurseTable(Tbl: {}, FilterFunction, RanFunction)
	for index, value in pairs(Tbl) do
		if type(value) == 'table' and FilterFunction(index, value) == true then
			RecurseTable(value, FilterFunction, RanFunction)
		else
			RanFunction(index, value, Tbl)
		end
	end
end

--
local System = {}

function System:AddQuest(Player: Player, Quest: Types.Quest)
	local PlayerData = DataManager:GetData(Player)
	local QuestType = Quest.Type

	if not(PlayerData.Quests[QuestType]) then
		PlayerData.Quests[QuestType] = {}
	end

	local QuestId = string.sub(QuestType, 1, 1)..string.format('%03i', #PlayerData.Quests[QuestType] + 1)
	Quest.ID = QuestId
	Quest.NuID = #PlayerData.Quests[QuestType]
	Quest.RegisterDate = DateTime.now().UnixTimestampMillis

	table.insert(PlayerData.Quests[QuestType], Quest)
end

function System:RemoveQuest(Player: Player, Quest_Id: string): ()
	local PlayerData = DataManager:GetData(Player)
	if not(PlayerData) then
		return
	end

	local Quest, Index = System:GetQuest(Player, Quest_Id)
	local Table = PlayerData.Quests[ReverseTypeLookup[string.sub(Quest.Type, 1, 1)]]

	if not(Table) then
		return
	end

	table.remove(Table, Index)
end


function System:RefreshDailies(Player: Player)
	local PlayerData = DataManager:GetData(Player)
	if not(PlayerData) then
		return
	end

	local Continue = not(#PlayerData.Quests.Daily > 0)
	for _, Quest: Types.Quest in PlayerData.Quests.Daily do
		local CreationDate = DateTime.fromUnixTimestampMillis(Quest.RegisterDate):ToUniversalTime()

		if CreationDate.Minute ~= DateTime.now():ToUniversalTime().Minute then
			Continue = true
			break
		end
	end

	if not(Continue) then return end

	PlayerData.Quests.Daily = {}
	PlayerData.Quests.Infinite = {}

	for _, Quest in CreateRandomDailyQuests() do
		System:AddQuest(Player, Quest)
	end

	for _, Quest in CreateRandomInfiniteQuests() do
		System:AddQuest(Player, Quest)
	end

	DataManager:UpdateData(Player)
end

function System:GetQuestRewards(Player: Player, Quest_Index: string): Types.Quest_Rewards
	local Quest = System:GetQuest(Player, Quest_Index)
	if not(Quest) then
		return {}
	end

	return Quest.Rewards
end

function System:GetQuest(Player: Player, Quest_Index: string): Types.Quest?
	local PlayerData = DataManager:GetData(Player)
	if not(PlayerData) then
		return
	end

	local Category = ReverseTypeLookup[string.sub(Quest_Index, 1, 1)]
	local PlayerQuests = Category and PlayerData.Quests[Category]

	if not(Category) or not(PlayerQuests) then
		return
	end

	for Index, Quest: Types.Quest in PlayerQuests :: {Types.Quest} do
		if Quest.ID == Quest_Index then
			return Quest, Index
		end
	end
end

function System:ClaimQuest(Player: Player, Quest_Index: string): ()
	local Rewards = System:GetQuestRewards(Player)

	System:RemoveQuest(Player, Quest_Index)
end

function System:WrapQuestData(Quest_Data: Types.Quest_Data): Types.Quest
	local Progress = {}

	for Key, Value in Quest_Data.Goals do
		if typeof(Value) == 'boolean' then
			Progress[Key] = false
		elseif typeof(Value) == 'number' then
			Progress[Key] = 0
		end
	end

	return {
		Type = Quest_Data.Type,
		Rewards = Quest_Data.Rewards,
		Goals = Quest_Data.Goals,
		BaseQuest = Quest_Data.Base_Quest,
		Progress = Progress,
		Extra = Quest_Data.Extra,
	} :: Types.Quest
end

function System:AddProgress(Player: Player, ProgressName: string, NewValue: boolean|number): ()
	local PlayerData = DataManager:GetData(Player)
	if not(PlayerData) then
		return
	end

	-- a lil ugly im sorry :3 but this is the only way i think it would make sense
	RecurseTable(PlayerData.Quests, 
		function(Index, Value)
			return Index ~= "Goals"
		end, --Filters to make sure we're not going through the Goals, cuz we don't need to
		function(Index, Value, Table)
			if Index == ProgressName then
				Table[Index] = (tonumber(NewValue) and Value + NewValue or NewValue)
			end
		end)
	
	UpdateQuest:Fire(Player, PlayerData.Quests)
end

-- # Private methods
function CreateRandomDailyQuests()
	local Dailies = table.clone(PremadeQuests.Daily)
	local Keys = {}
	local Quests = {}

	for Key in Dailies do
		if Key == 'Daily Quests Completed' then continue end
		table.insert(Keys, Key)
	end

	for i = 1, 5 do
		local NewQuest = Keys[math.random(1, #Keys)]
		local DailyQuestInfo = Dailies[NewQuest]
		
		if NewQuest == "Daily Quests Complete" then
			repeat
				NewQuest = Keys[math.random(1, #Keys)]
			until NewQuest ~= "Daily Quests Complete"
		end
		
		local QuestObject = System:WrapQuestData({
			Type = 'Daily',
			Base_Quest = NewQuest,
			Rewards = DailyQuestInfo.Rewards,
			Goals = DailyQuestInfo.Goals,
		})

		table.insert(Quests, QuestObject)
		table.remove(Keys, table.find(Keys, NewQuest))
	end

	table.insert(Quests, System:WrapQuestData({
		Type = 'Daily',
		Base_Quest = 'Daily Quests Complete',
		Rewards = PremadeQuests.Daily["Daily Quests Complete"].Rewards,
		Goals = PremadeQuests.Daily["Daily Quests Complete"].Goals,
	}))

	return Quests
end

function CreateRandomInfiniteQuests()
	local Worlds = table.clone({'Shells Town', 'Namek'})
	local Quests = {}

	for _ = 1, math.min(#Worlds, 3) do
		local idx = math.random(1, #Worlds)
		local World = Worlds[idx]

		for i = 0, 2 do
			local BaseId = 'Waves I'..string.rep('I', i)
			local GoalQuest = PremadeQuests.Infinite[BaseId]

			local QuestObject = System:WrapQuestData({
				Type = 'Infinite',
				Base_Quest = BaseId,
				Rewards = GoalQuest.Rewards,
				Goals = GoalQuest.Goals,

				Extra = World,
			})

			table.insert(Quests, QuestObject)
		end

		table.remove(Worlds, idx)
	end

	return Quests
end

return System
