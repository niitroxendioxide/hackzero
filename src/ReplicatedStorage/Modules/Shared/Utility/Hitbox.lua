local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Hitbox = {}
local Types = require(ReplicatedStorage.Modules.Shared.Types)

function Hitbox:IsPointInArea(Point: Vector3, Size: Vector3, At: CFrame)
	local v3 = At:PointToObjectSpace(Point)
	return (math.abs(v3.X) <= Size.X / 2)
		and (math.abs(v3.Y) <= Size.Y / 2)
		and (math.abs(v3.Z) <= Size.Z / 2)
end

function Hitbox:GetPartsInArea(List: {},  Size: Vector3, At: CFrame)
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = List
	
	local Parts = workspace:GetPartBoundsInBox(At, Size, Params)
	
	return Parts
end


function Hitbox:ForAgentsInZone(Agents: {GetActiveAgentsHitboxes: (self: {}) -> ({}, {})}, Size: Vector3, At: CFrame, fn: (Agent: Types.ServerAgentClass) -> ())
	local Params = OverlapParams.new()
	local Hitboxes, Whitelist = Agents:GetActiveAgentsHitboxes()

	Params.FilterDescendantsInstances = Whitelist
	Params.FilterType = Enum.RaycastFilterType.Include
	
	local PartsInZone = workspace:GetPartBoundsInBox(At, Size, Params)

	for _, Part in PartsInZone do
		local Agent = Hitboxes[Part]

		if Agent then
			task.spawn(fn, Agent)
		end
	end
end


return Hitbox
