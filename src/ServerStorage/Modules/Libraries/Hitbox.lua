--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)

local StructureTypes = require(Shared.Types.Structures)
local Agents = require(script.Parent.Agents)
local Structures = require(script.Parent.StructureList)

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

		if Agent and Agent:IsAlive() then
			task.spawn(fn, Agent)
		end
	end
end

function Hitbox:ForStructuresInZone(Size: Vector3, At: CFrame, fn: (Structure: StructureTypes.DestructibleServerEntity) -> ())
	local Map, Colliders = Structures:GetAllColliders()
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = Colliders

	local PartsInZone = workspace:GetPartBoundsInBox(At, Size, Params)
	for _, Part in PartsInZone do
		local StructureAssigned = Map[Part]

		if StructureAssigned then
			task.spawn(fn, StructureAssigned)
		end

	end
end

return Hitbox
