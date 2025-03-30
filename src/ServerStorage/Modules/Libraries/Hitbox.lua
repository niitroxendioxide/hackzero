--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Agents = require(script.Parent.Agents)

--
local Hitbox = {}

function Hitbox:ForAgentsInZone(Size: Vector3, At: CFrame, fn: (Agent: Types.ServerAgentClass) -> ())
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
