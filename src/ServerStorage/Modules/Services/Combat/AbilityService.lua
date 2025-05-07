--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local Enemies = require(Shared.Libraries.Enemies)
local GameEnum = require(Shared.GameEnum)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local AgentLibrary = require(ServerStorage.Modules.Libraries.Agents)
local MovesetLibrary = require(ServerStorage.Modules.Libraries.Movesets)

--
local Service = {
	__Movesets = {},
}

function Service:Init()
	MovesetLibrary:Init()

	Network.new("Ability", "Event")
	Network:On('Ability', Service.ReplicateEvent)
end

function Service.ReplicateEvent(Player: Player, ClientBuffer: buffer)
	local Type = buffer.readu8(ClientBuffer, 0)

	if Type == GameEnum.Replication.UseSkill then

		local SkillId = buffer.readu8(ClientBuffer, 1)
		local EnemyId = buffer.readu8(ClientBuffer, 2)
		local ActiveAgent, AgentId = AgentLibrary:GetCurrentActive(Player:GetAttribute("ReplicationId") :: number)

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

function Service:PromptAssist(Agent: Types.ServerAgentClass)
	--
	

end

function Service:GetMoveset(Name: string)
	return MovesetLibrary:Get(Name) or Service:GetMoveset("Goku")
end

return Service
