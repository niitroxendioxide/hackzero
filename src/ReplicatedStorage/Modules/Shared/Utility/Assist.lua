--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Agents)

local Rng = require(script.Parent.Random)

--
local AssistUtil = {}

local function LookAt(e: Types.AgentClass, cfOffset: CFrame, from: Types.AgentClass)
	local PosCF = e:GetPivot() * cfOffset
	local LookV = CFrame.lookAt(e:GetPivot().Position, from:GetPivot().Position).LookVector

	return CFrame.lookAlong(PosCF.Position, LookV) --* CFrame.Angles(0, math.pi, 0)
end

function AssistUtil:CalculateSwitchCFrame(CurrentAgent: Types.AgentClass & Types.ServerAgentClass, Direction: number, EnemyTarget: Types.AgentClass?)
	local CurrentPivot = CurrentAgent:GetPivot()

	local Offset = CFrame.new()
	local WasMoving = CurrentAgent:IsMoving()
	if not WasMoving then
		Offset = CFrame.new(Direction * 4, 0, 6)
	end

	CurrentAgent:Stop()

	local Location = CurrentPivot * Offset
	if EnemyTarget then
		local Dot = EnemyTarget:GetPivot().LookVector:Dot(CFrame.new(EnemyTarget:GetPivot().Position, CurrentAgent:GetPivot().Position).LookVector)
		local SideOffset = Rng:NextInteger(-4, 4)

		if Dot < 0 then
			Location = LookAt(EnemyTarget, CFrame.new(SideOffset, 0, -10), CurrentAgent)
		else
			Location = LookAt(EnemyTarget, CFrame.new(SideOffset, 0, 10), CurrentAgent)
		end
	end


	return Location
end

return AssistUtil
