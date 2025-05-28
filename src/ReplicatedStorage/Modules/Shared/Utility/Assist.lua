--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local AssistUtil = {}

function AssistUtil:CalculateSwitchCFrame(Agent: Types.GenericClass, Direction: number, EnemyTarget: Types.GenericClass?)
	local CurrentCharacter = Agent
	local CurrentPivot = CurrentCharacter:GetPivot()

	local Offset = CFrame.new()
	local WasMoving = CurrentCharacter:IsMoving()
	if not WasMoving then
		Offset = CFrame.new(Direction * 4, 0, 6)
	end

	local Location = CurrentPivot * Offset
	if EnemyTarget then
		Location = EnemyTarget:GetPivot() * CFrame.new(0, 0, -4)
	end

	CurrentCharacter:Stop()

	return Location
end

return AssistUtil
