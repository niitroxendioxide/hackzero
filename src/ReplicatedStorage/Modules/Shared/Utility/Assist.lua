--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Math = require(script.Parent.Math)
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
	local CurrentArea = CurrentAgent:GetLimitArea()

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

	if CurrentArea then
		local IsInBox = Math:IsPointInBox(Location, CurrentArea, 1.25)

		if IsInBox then
			return Location
		end

		if EnemyTarget then
			local CentreCF = CFrame.lookAt(EnemyTarget:GetPivot().Position, CurrentArea.Position)

			Location = CentreCF * CFrame.new(Rng:NextNumber(-2, 2), 0, -2.5) * CFrame.Angles(0, math.pi, 0)

			return Location
		end

		Location = CurrentPivot * CFrame.new(0, 0, 0.15)
	end

	return Location
end

return AssistUtil
