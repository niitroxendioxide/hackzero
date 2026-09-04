--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Math = require(script.Parent.Math)
local Types = require(Shared.Types.Agents)

--
local AssistUtil = {}

-- Studs of clearance kept from an arena wall when a switch lands out of bounds.
local AREA_INSET = 2
local AREA_SIZE_MODIFIER = 1.25

local function LookAt(e: Types.AgentClass, cfOffset: CFrame, from: Types.AgentClass)
	local PosCF = e:GetPivot() * cfOffset
	local LookV = CFrame.lookAt(e:GetPivot().Position, from:GetPivot().Position).LookVector

	return CFrame.lookAlong(PosCF.Position, LookV) --* CFrame.Angles(0, math.pi, 0)
end

--[[
	Where the incoming agent lands on a character switch.

	Pure: it reads the outgoing agent's pose but does not touch it -- callers
	stop the previous agent themselves.

	Every random draw comes from a Random seeded with the caller supplied Seed
	rather than a shared singleton. Client and server consume a shared singleton
	at different rates, so its stream position diverges and the two sides can
	never agree on a position. With the seed travelling in the switch packet
	both sides compute the identical CFrame, which is what makes client side
	prediction of a switch safe.

	@param Seed Shared per-switch seed. Both sides must pass the same value.
]]
function AssistUtil:CalculateSwitchCFrame(CurrentAgent: Types.AgentClass & Types.ServerAgentClass, Direction: number, EnemyTarget: Types.AgentClass?, ForceRotateVector: boolean?, Seed: number?)
	local CurrentPivot = CurrentAgent:GetPivot()
	local CurrentArea = CurrentAgent:GetLimitArea()
	local Rng = Random.new(Seed or 0)

	local Offset = CFrame.new()
	local WasMoving = CurrentAgent:IsMoving()
	if not WasMoving then
		Offset = CFrame.new(math.sign(Direction) * 4, 0, 6)
	end

	local Location = CurrentPivot * Offset
	if EnemyTarget then
		local Dot = EnemyTarget:GetPivot().LookVector:Dot(CFrame.new(EnemyTarget:GetPivot().Position, CurrentAgent:GetPivot().Position).LookVector)
		local SideOffset = Rng:NextInteger(-4, 4)

		if Dot < 0 or ForceRotateVector then
			Location = LookAt(EnemyTarget, CFrame.new(SideOffset, 0, -10), CurrentAgent)
		else
			Location = LookAt(EnemyTarget, CFrame.new(SideOffset, 0, 10), CurrentAgent)
		end
	end

	if CurrentArea then
		if Math:IsPointInBox(Location, CurrentArea, AREA_SIZE_MODIFIER) then
			return Location
		end

		if EnemyTarget then
			local CentreCF = CFrame.lookAt(EnemyTarget:GetPivot().Position, CurrentArea.Position)

			Location = CentreCF * CFrame.new(Rng:NextNumber(-2, 2), 0, -2.5) * CFrame.Angles(0, math.pi, 0)
		end

		-- Final guarantee: whatever the branch above produced, a switch can
		-- never drop an agent outside the area it is bound to.
		Location = Math:ClampPointToBox(Location, CurrentArea, AREA_SIZE_MODIFIER, AREA_INSET) :: CFrame
	end

	return Location
end

return AssistUtil
