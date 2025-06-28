--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types.Agents)
local AgentTypes = require(Shared.Types.Agents)
local Statics = require(Database.Statics)
local AssistUtil = require(Shared.Utility.Assist)
local Enemies = require(Shared.Libraries.Enemies)
local InterfaceStates = require(Client.Packages.InterfaceStates)
--
local Characters = {
	__Player_Data = {} :: {[number]: {Active: number, List: {AgentTypes.AgentClass}}},
	__Targets = {},
	__Target_Threads = {},
}

function Characters:GetCharacterTarget(Player: Player)
	return Characters.__Targets[Player]
end

function Characters:SetCharacterTarget(Player: Player, Id: number, Time: number)
	if Characters.__Target_Threads[Player] then
		task.cancel(Characters.__Target_Threads[Player])
	end

	Characters.__Targets[Player] = Id

	Characters.__Target_Threads[Player] = task.delay(Time, function()
		Characters.__Targets[Player] = nil
		Characters.__Target_Threads[Player] = nil
	end)
end

function Characters:Switch(ReplicationId: number, Direction: number, EnemyTargetId: number)
	Characters:Build(ReplicationId)

	--
	local IsLocal = Players.LocalPlayer:GetAttribute("ReplicationId") == ReplicationId
	Direction = math.sign(Direction)

	local CurrentCharacter = Characters:GetCurrent(ReplicationId)
	local Data = Characters.__Player_Data[ReplicationId]
	local TargetObject = EnemyTargetId and Enemies:GetEnemy(EnemyTargetId)
	local NewCFrame = AssistUtil:CalculateSwitchCFrame(Data.List[Data.Active], Direction, TargetObject)

	if Data.Active + Direction > #Data.List then
		Data.Active = 1
	elseif Data.Active + Direction < 1 then
		Data.Active = #Data.List
	else
		Data.Active += Direction
	end

	local Count = 0
	while not Data.List[Data.Active]:IsAlive() do
		if Count > 3 then

			return false
		end

		Data.Active += 1
		if Data.Active > #Data.List then
			Data.Active = 1
		elseif Data.Active < 1 then
			Data.Active = #Data.List
		end

		Count += 1
	end

	Data.Last_Anim = Data.Last_Anim == 1 and 2 or 1

	if Players.LocalPlayer:GetAttribute("ReplicationId") == ReplicationId then
		InterfaceStates.Characters:set(Data)
	end

	--
	CurrentCharacter:SetVisible(false)


	local NewCharacter = Characters:GetCurrent(ReplicationId)
	if CurrentCharacter == NewCharacter then
		return false
	end

	local Animator = NewCharacter:GetAnimator()
	NewCharacter:PivotTo(NewCFrame, not IsLocal)
	Animator:Play('Dash'..(Data.Last_Anim == 2 and 'Right' or 'Left'), {Name = 'Dash', Speed = 1.25})
	NewCharacter:SetVisible(true)

	local Force = TargetObject and 30 or 75
	NewCharacter:ApplyImpulse(NewCFrame.LookVector * Force)

	return true
end

function Characters:Add(ReplicationId: number, Character: AgentTypes.AgentClass)
	Characters:Build(ReplicationId)

	local Data = Characters.__Player_Data[ReplicationId]

	if #Data.List >= Statics.Max_Team_Size then
		warn('Cannot add character to team, reason: Team is already full')

		return
	end

	table.insert(Data.List, Character)

	if Players.LocalPlayer:GetAttribute("ReplicationId") == ReplicationId then
		InterfaceStates.Characters:set(Data)
	end
end

function Characters:Remove(ReplicationId: number, Name: string): any
	local Data = Characters.__Player_Data[ReplicationId]

	for key, Character in Data.List do
		if Character.Name == Name then
			table.remove(Data.List, key)

			return Character
		end
	end

	if Players.LocalPlayer:GetAttribute("ReplicationId") == ReplicationId then
		InterfaceStates.Characters:set(Data)
	end

	return;
end

function Characters:GetCurrent(ReplicationId: number): (AgentTypes.AgentClass?, number?)
	local Data = Characters.__Player_Data[ReplicationId]
	if not Data then
		return nil, nil;
	end

	local CurrentActive = Data.Active

	return Data.List[CurrentActive], CurrentActive
end

function Characters:GetAgent(ReplicationId: number, Id: number): AgentTypes.AgentClass?
	local Data = Characters.__Player_Data[ReplicationId]
	if not Data then
		return;
	end

	return Data.List[Id]
end

function Characters:HasCharacter(ReplicationId: number, Name: string): boolean
	if not Characters.__Player_Data[ReplicationId] then
		return false
	end

	local Data = Characters.__Player_Data[ReplicationId]

	for _, Character in Data.List do
		if Character.Name == Name then
			return true
		end
	end

	return false;
end

--
function Characters:Build(ReplicationId: number)
	if Characters.__Player_Data[ReplicationId] then
		return
	end

	Characters.__Player_Data[ReplicationId] = {
		Active = 1,
		List = {},
	}
end

function Characters:GetCharacters(ReplicationId: number): {[number]: AgentTypes.AgentClass}
	if not Characters.__Player_Data[ReplicationId] then
		return {}
	end

	return Characters.__Player_Data[ReplicationId].List
end

function Characters:GetCurrentName(ReplicationId: number): string
	local Current = Characters:GetCurrent(ReplicationId)
	if not Current then return '' end

	return Current.Name
end

function Characters:RemoveAll(ReplicationId: number)
	Characters.__Player_Data[ReplicationId] = nil
end

function Characters:GetActiveAgentsHitboxes()
	local Active, List = {}, {}

	for userId, PlayerAgents in Characters.__Player_Data do
		for _, Agent in PlayerAgents.List do
			if Characters:GetCurrent(userId) == Agent then
				Active[Agent:GetHitbox()] = Agent
				table.insert(List, Agent:GetHitbox())
				break
			end
		end
	end

	return Active, List
end


return Characters
