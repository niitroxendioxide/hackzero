--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local AgentTypes = require(Shared.Types.Agents)
local Statics = require(Database.Statics)
local AssistUtil = require(Shared.Utility.Assist)
local Enemies = require(Shared.Libraries.Enemies)
local InterfaceStates = require(Client.Packages.InterfaceStates)

--
local Characters = {
	__Player_Data = {} :: {[number]: {Active: number, List: {AgentTypes.AgentClass}}},
	-- Client mirror of ServerAgentClass.__Current_Target, so both sides feed
	-- AssistUtil:CalculateSwitchCFrame the same target and land in the same spot.
	__Marked = {} :: {[Player]: AgentTypes.MarkedEnemyStruct},
	__Marked_Threads = {} :: {[Player]: thread},
	__Current_Hitting_Target = 0,

	SwitchedToAssist = Signal.new(),
}

local Switch_Threads = {}

function Characters:GetMarkedTarget(Player: Player): AgentTypes.MarkedEnemyStruct?
	return Characters.__Marked[Player]
end

function Characters:GetCharacterTarget(Player: Player): number?
	local Marked = Characters.__Marked[Player]

	return Marked and Marked.TargetId or nil
end

function Characters:GetCharacterFromHitbox(Hitbox: BasePart)
	for _, Player in Characters.__Player_Data do
		for _, Char in Player.List do
			if Char:GetHitbox() == Hitbox then
				return Char
			end
		end
	end

	return;
end

--[[
	Mirror of ServerAgentClass:MarkTarget. Records both the enemy to orient the
	switch around and the agent the prompt wants switched in, so an assist swap
	predicts identically to what the server computes.

	Passing a nil TargetId (or a non positive Time) clears the mark and its
	expiry thread.
]]
function Characters:MarkTarget(Player: Player, TargetId: number?, Time: number?, AssistCharacterId: number?)
	if Characters.__Marked_Threads[Player] then
		task.cancel(Characters.__Marked_Threads[Player])
		Characters.__Marked_Threads[Player] = nil
	end

	if TargetId == nil or (Time or 0) <= 0 then
		Characters.__Marked[Player] = nil

		return
	end

	Characters.__Marked[Player] = {
		TargetId = TargetId,
		AssistCharacterId = AssistCharacterId,
		Time = Time :: number,
		Deadline = os.clock() + (Time :: number),
	}

	Characters.__Marked_Threads[Player] = task.delay(Time, function()
		Characters.__Marked[Player] = nil
		Characters.__Marked_Threads[Player] = nil
	end)
end

--[[
	Local (predicted) switch for the player who owns this client.

	Returns the seed it rolled alongside the result, and the caller must send
	that seed to the server in the CharacterSwitch packet: the server recomputes
	the destination with AssistUtil and only agrees with this prediction if it
	draws from an identically seeded Random.

	@return Result, NewIndex, Seed
]]
function Characters:Switch(ReplicationId: number, Direction: number, EnemyTargetId: number?, ForceRotate: boolean?)
	Characters:Build(ReplicationId)

	--
	Direction = math.sign(Direction)

	local Seed = math.random(0, 255)
	local CurrentCharacter = Characters:GetCurrent(ReplicationId)
	local Data = Characters.__Player_Data[ReplicationId]
	local PreviousAgent = Data.List[Data.Active]

	local IsLocal = Players.LocalPlayer:GetAttribute("ReplicationId") == ReplicationId
	local Marked = IsLocal and Characters.__Marked[Players.LocalPlayer] or nil

	-- Same precedence the server applies: a live mark outranks whatever the
	-- caller passed, in both directions. Resolving this only on forward swaps
	-- (as the caller used to) made a backward swap during a prompt compute
	-- without a target while the server computed with one.
	local TargetObject = EnemyTargetId and Enemies:GetEnemy(EnemyTargetId) or nil
	if Marked and Marked.TargetId then
		TargetObject = Enemies:GetEnemy(Marked.TargetId)
	end

	local NewCFrame = AssistUtil:CalculateSwitchCFrame(PreviousAgent, Direction, TargetObject, ForceRotate, Seed)

	PreviousAgent:Stop()

	if Marked and (Marked.AssistCharacterId or 0) > 0 then
		Data.Active = Marked.AssistCharacterId :: number
		Characters:MarkTarget(Players.LocalPlayer, nil)
		Characters.SwitchedToAssist:Fire()
	else
		if Data.Active + Direction > #Data.List then
			Data.Active = 1
		elseif Data.Active + Direction < 1 then
			Data.Active = #Data.List
		else
			Data.Active += Direction
		end
	end

	local Count = 0
	while not Data.List[Data.Active]:IsAlive() do
		if Count > 3 then
			return false
		end

		Data.Active += Direction
		if Data.Active > #Data.List then
			Data.Active = 1
		elseif Data.Active < 1 then
			Data.Active = #Data.List
		end

		Count += 1
	end

	local CurrentAgentDataId = Data.Active
	local Result = Characters:HandleSwitchFor(ReplicationId, CurrentCharacter, NewCFrame, false, TargetObject ~= nil)

	return Result, CurrentAgentDataId, Seed
end

--[[
	Switch driven by the server's CharacterSwitch broadcast. The destination is
	decoded from the packet rather than recomputed, so a remote client never has
	to reproduce the server's random draws.
]]
function Characters:SwitchToIndex(RepId: number, Idx: number, At: CFrame, HasTarget: boolean?): boolean
	local Data = Characters.__Player_Data[RepId]
	if not Data or not Data.List[Idx] then
		return false
	end

	local Previous = Characters:GetCurrent(RepId)
	Previous:Stop()

	Data.Active = Idx

	--
	return Characters:HandleSwitchFor(RepId, Previous, At, true, HasTarget)
end

function Characters:HandleSwitchFor(RepId: number, Previous: Types.AgentClass, At: CFrame, Snap: boolean?, HasTarget: boolean?)
	local Data = Characters.__Player_Data[RepId]

	Data.Last_Anim = Data.Last_Anim == 1 and 2 or 1

	if Players.LocalPlayer:GetAttribute("ReplicationId") == RepId then
		InterfaceStates.Characters:set(Data)
	end

	--
	local NewCharacter = Characters:GetCurrent(RepId)
	if Previous == NewCharacter then
		return false
	end

	if Switch_Threads[NewCharacter] then
		task.cancel(Switch_Threads[NewCharacter])
		Switch_Threads[NewCharacter] = nil;
	end

	if Previous:GetState() ~= 'Idle' then
		if Switch_Threads[Previous] then
			task.cancel(Switch_Threads[Previous])
			Switch_Threads[Previous] = nil
		end

		Switch_Threads[Previous] = task.spawn(function()
			while Previous:GetState() ~= 'Idle' do
				task.wait()
			end

			Previous:SetVisible(false)
		end)

	else
		Previous:SetVisible(false)
	end
	

	local Animator = NewCharacter:GetAnimator()
	NewCharacter:SetVisible(true)

	if not NewCharacter:HasTag("CharacterStatic") then
		NewCharacter:PivotTo(At, Snap)

		if not HasTarget then
			Animator:Play('DashForth', {Name = 'Dash', Speed = 1.25})
			NewCharacter:ImpulseForward(Statics.Switch_Character_Dash_Strength, 0.75)
		end
	end

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

	--[[table.sort(Data.List, function(a, b)
		return a.Name > b.Name
	end)]]

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

function Characters:GetCurrent(ReplicationId: number?): (AgentTypes.AgentClass?, number?)
	if ReplicationId == nil and RunService:IsClient() then
		ReplicationId = Players.LocalPlayer:GetAttribute('ReplicationId') :: number
	elseif ReplicationId == nil then return end

	local Data = Characters.__Player_Data[ReplicationId :: number]
	if not Data then
		return nil, nil;
	end

	local CurrentActive = Data.Active

	return Data.List[CurrentActive], CurrentActive
end

function Characters:GetAliveCount(RepId: number?)
	local Id = RepId or Players.LocalPlayer:GetAttribute('ReplicationId') :: number
	local All = Characters:GetCharacters(Id)

	local Counter = 0
	for _, Agent in All do
		Counter += Agent:IsAlive() and 1 or 0
	end

	return Counter
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

function Characters:GetCharacters(ReplicationId: number?): {[number]: AgentTypes.AgentClass}
	if ReplicationId == nil then ReplicationId = Players.LocalPlayer:GetAttribute("ReplicationId") end

	if not Characters.__Player_Data[ReplicationId :: number] then
		return {}
	end

	return Characters.__Player_Data[ReplicationId :: number].List
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

function Characters:GetAllHitboxes()
	local HitboxList = {}
	for userId, PlayerAgents in Characters.__Player_Data do
		for _, Agent in PlayerAgents.List do
			table.insert(HitboxList, Agent:GetHitbox())
		end
	end

	return HitboxList
end


return Characters
