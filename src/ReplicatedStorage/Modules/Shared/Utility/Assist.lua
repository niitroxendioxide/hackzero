--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local AssistUtil = {}

function AssistUtil:CalculateSwitchCFrame(Agents: {Types.AgentClass}, Current: number, Direction: number)
	local CurrentCharacter =  Agents[Current]
	local CurrentPivot = CurrentCharacter:GetPivot()

	local Offset = CFrame.new()
	local WasMoving = CurrentCharacter:IsMoving() 
	if not WasMoving then
		Offset = CFrame.new(Direction * 4, 0, 6)
	end

	CurrentCharacter:Stop()
	
	return CurrentPivot * Offset
end

return AssistUtil
