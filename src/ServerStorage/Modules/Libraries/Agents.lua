--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Types = require(ReplicatedStorage.Modules.Shared.Types.Agents)

--
local Agents = {
	__Players = {}
}

function Agents:Add(UserId: number, Agent)
	if not Agents.__Players[UserId] then
		Agents.__Players[UserId] = {}
	end

	if #Agents.__Players[UserId] + 1 > 3 then
		return warn('Too many characters bro!')
	end

	table.insert(Agents.__Players[UserId], Agent)

	return;
end

function Agents:Remove(UserId: number, Agent)
	if not Agents.__Players[UserId] then
		return
	end

	for key, SavedAgent in Agents.__Players[UserId] do
		if Agent == SavedAgent or Agent.Name == SavedAgent.Name then
			table.remove(Agents.__Players[UserId], key)
		end
	end
end

function Agents:GetActiveAgents()
	local Active = {}

	for _, PlayerAgents in Agents.__Players do
		for _, Agent in PlayerAgents do
			if Agent.__Active and Agent:IsAlive() then
				table.insert(Active, Agent)
				break
			end
		end
	end

	return Active
end

function Agents:GetActiveAgentsHitboxes()
	local Active, List = {}, {}

	for _, PlayerAgents in Agents.__Players do
		for _, Agent in PlayerAgents do
			if Agent.__Active or Agent:HasTag('CanBeTargetted') then
				Active[Agent:GetHitbox()] = Agent
				table.insert(List, Agent:GetHitbox())
			end
		end
	end

	return Active, List
end

function Agents:GetAll(UserId: number): {Types.AgentClass | Types.ServerAgentClass}
	if not Agents.__Players[UserId]  then
		return {};
	end

	return table.clone(Agents.__Players[UserId])
end

function Agents:GetAllAliveAgents(): { Types.ServerAgentClass }
	local List = {}

	for _, PlayerList in Agents.__Players do
		for _, Agent in PlayerList do
			if not Agent:IsAlive() then continue end

			table.insert(List, Agent)
		end
	end

	return List
end

function Agents:GetAlive(UserId: number): {Types.AgentClass | Types.ServerAgentClass}
	local All = Agents:GetAll(UserId)

	local List = {}
	for _, Agent in All do
		if not Agent:IsAlive() then continue end
		table.insert(List, Agent)
	end

	return List
end

function Agents:GetIdForPlayer(UserId: number, AgentParameter: Types.ServerAgentClass): (number)
	for Id, UserAgent in Agents:GetAll(UserId) do
		if UserAgent == AgentParameter then
			return Id;
		end
	end

	return 1;
end

function Agents:GetCurrentActive(UserId: number): (Types.AgentClass?, number?)
	if not Agents.__Players[UserId]  then
		return;
	end
	
	for Id, Agent in Agents.__Players[UserId] do
		if Agent.__Active then
			return Agent, Id
		end
	end

	return;
end

return Agents
