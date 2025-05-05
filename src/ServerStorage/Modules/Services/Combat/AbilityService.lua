--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Enemies = require(Shared.Libraries.Enemies)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)
local MovesetLibrary = require(ServerStorage.Modules.Libraries.Movesets)

local Components = ServerStorage.Modules.Components

--
local Service = {
	__Movesets = {},
}

function Service:Init()
	MovesetLibrary:Init()

	for _, Moveset in Components.Movesets:GetChildren() do
		local Success, Required = pcall(require, Moveset)

		if Success and typeof(Required) == 'table' then
			Service.__Movesets[Moveset.Name] = Required
		end
	end

	Network.new("Ability", "Event")
	Network:On('Ability', Service.ReplicateEvent)
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer)
	local Type = buffer.readu8(ClientBuffer, 0)

	if Type == GameEnum.Replication.UseSkill then

		local SkillId = buffer.readu8(ClientBuffer, 1)
		local EnemyId = buffer.readu8(ClientBuffer, 2)
		local ActiveAgent, AgentId = AgentLibrary:GetCurrentActive(Player.UserId)
		local Moveset = Service:GetMoveset(ActiveAgent.Name)
		local Skill = GameEnum.KeyLookup(GameEnum.Skills, SkillId)
		local Enemy = Enemies:GetEnemy(EnemyId)
		local XZ = Vector3.new(1, 0, 1)

		--

		--
		local LookAt = ActiveAgent:GetPivot().LookVector
		if Enemy then
			LookAt = CFrame.lookAt(ActiveAgent:GetPivot().Position * XZ, Enemy:GetPivot().Position * XZ).LookVector
		end

		if Skill ~= 'Dodge' then
			ActiveAgent:Look(LookAt)
		elseif Skill == 'Dodge' then
			for _, Character in AgentLibrary:GetAll(Player.UserId) do
				Character:SetKey('Sprint', true)
				Character:SetKey('Jog', true)
			end
		end

		Moveset:Begin(Skill, ActiveAgent)

		Replicator:UseSkill(Player, SkillId, AgentId, EnemyId)
	end
end

function Service:PromptAssist()
	
end

function Service:GetMoveset(Name: string)
	return Service.__Movesets[Name] or Service:GetMoveset("Goku")
end

return Service
