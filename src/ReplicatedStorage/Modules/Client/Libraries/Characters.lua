--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Statics = require(Database.Statics)
local AssistUtil = require(Shared.Utility.Assist)
local IsClient = RunService:IsClient()
local InterfaceStates = IsClient and require(Client.Packages.InterfaceStates)

--
local Characters = {
	__Player_Data = {} :: {[number]: {Active: number, List: {Types.AgentClass}}},
}

function Characters:Switch(UserId: number, Direction: number)
	Characters:Build(UserId)

	--	
	Direction = math.sign(Direction)
	
	local CurrentCharacter = Characters:GetCurrent(UserId)
	local Data = Characters.__Player_Data[UserId]
	local NewCFrame = AssistUtil:CalculateSwitchCFrame(Data.List, Data.Active, Direction)
	
	if Data.Active + Direction > #Data.List then
		Data.Active = 1
	elseif Data.Active + Direction < 1 then
		Data.Active = #Data.List
	else
		Data.Active += Direction
	end
	
	Data.Last_Anim = Data.Last_Anim == 1 and 2 or 1
	
	if IsClient and Players.LocalPlayer.UserId == UserId then
		InterfaceStates.Characters:set(Data)
	end
	
	--
	CurrentCharacter:SetVisible(false)
	

	local NewCharacter = Characters:GetCurrent(UserId)
	local Animator = NewCharacter:GetAnimator()
	Animator:Play('Dash'..(Data.Last_Anim == 2 and 'Right' or 'Left'), {Name = 'Dash', Speed = 1.25})
	NewCharacter:SetVisible(true)
	NewCharacter:PivotTo(NewCFrame)
	NewCharacter:ApplyImpulse(NewCFrame.LookVector * 75)
end

function Characters:Add(UserId: number, Character: Types.AgentClass)
	Characters:Build(UserId)
	
	local Data = Characters.__Player_Data[UserId]
	
	if #Data.List >= Statics.Max_Team_Size then
		warn('Cannot add character to team, reason: Team is already full')
		
		return
	end

	table.insert(Data.List, Character)
	
	if IsClient and Players.LocalPlayer.UserId == UserId then
		InterfaceStates.Characters:set(Data)
	end
end

function Characters:Remove(UserId: number, Name: string): any
	local Data = Characters.__Player_Data[UserId]

	for key, Character in Data.List do
		if Character.Name == Name then
			table.remove(Data.List, key)

			return Character
		end
	end

	if IsClient and Players.LocalPlayer.UserId == UserId then
		InterfaceStates.Characters:set(Data)
	end

	return;
end

function Characters:GetCurrent(UserId: number): (Types.AgentClass?, number?)
	local Data = Characters.__Player_Data[UserId]
	if not Data then
		return nil, nil;
	end
	
	local CurrentActive = Data.Active
	
	return Data.List[CurrentActive], CurrentActive
end

function Characters:HasCharacter(UserId: number, Name: string): boolean
	if not Characters.__Player_Data[UserId] then
		return false
	end

	local Data = Characters.__Player_Data[UserId]

	for _, Character in Data.List do
		if Character.Name == Name then
			return true
		end
	end

	return false;
end

--
function Characters:Build(UserId: number)
	if Characters.__Player_Data[UserId] then
		return
	end

	Characters.__Player_Data[UserId] = {
		Active = 1,
		List = {},
	}
end

function Characters:GetCharacters(UserId: number): {[number]: Types.AgentClass}
	if not Characters.__Player_Data[UserId] then
		return {}
	end

	return Characters.__Player_Data[UserId].List
end

function Characters:GetCurrentName(UserId: number): string
	local Current = Characters:GetCurrent(UserId)
	if not Current then return '' end
	
	return Current.Name
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
