--
local Plastic = PhysicalProperties.new(Enum.Material.SmoothPlastic)
local AREA_OF_CONTACT = 1.8
local FrictionValues = {} :: {number}
local World = {
	CharacterAcceleration = 10,
	StepHeight = 1.895,
	
}

local WorldFolder = workspace:WaitForChild('World')

function World:GetSpeed(): number
	return 1
end

function World:GetAirFriction(): number
	return 20
end

function World:GetMapParams(Overlap: boolean?): OverlapParams | RaycastParams
	local Params = Overlap and OverlapParams.new() or RaycastParams.new()
	Params.FilterDescendantsInstances = {WorldFolder.Map}
	Params.FilterType = Enum.RaycastFilterType.Include

	return Params
end

function World:GetCollisionParams(Overlap: boolean?): OverlapParams | RaycastParams
	local Camera = workspace:FindFirstChild('Camera') :: Camera
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {
		WorldFolder.Map,
		WorldFolder.Entities:FindFirstChild("Destructibles"),
		WorldFolder.Entities.Colliders, Camera:FindFirstChild('Enemy_Collisions'),
		Camera:FindFirstChild("Destructibles")
	}

	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	return ParamsNew
end

function World:GetColliderParams(Overlap: boolean?): OverlapParams | RaycastParams
	local Camera = workspace:FindFirstChild('Camera') :: Camera
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {
		WorldFolder.Entities.Colliders,
		WorldFolder.Entities.Hitboxes,
		WorldFolder.Entities:FindFirstChild('Destructibles'),
		Camera:FindFirstChild('Enemy_Collisions'),
		Camera:FindFirstChild("Destructibles"),
	}

	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	return ParamsNew
end

function World:GetEnemyColliderParams(Overlap: boolean?): OverlapParams | RaycastParams
	local Camera = workspace:FindFirstChild('Camera') :: Camera
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {
		WorldFolder.Entities.Colliders,
		Camera:FindFirstChild('Enemy_Collisions'),
	}

	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	return ParamsNew
end

local function GetFrictionBetweenMaterial(Material)
	return (Plastic.Friction * Plastic.FrictionWeight + Material.Friction * Material.FrictionWeight) / (Plastic.FrictionWeight + Material.FrictionWeight)
end

function World:GetSurfaceFriction(At: Vector3): number
	local Params = World:GetMapParams() :: RaycastParams
	local Raycast = workspace:Raycast(At, Vector3.yAxis*-25, Params)

	if Raycast then
		if not FrictionValues[Raycast.Material] then
			local Properties = PhysicalProperties.new(Raycast.Material)
			--local Friction = Properties.Friction
			--local Weight = Properties.FrictionWeight

			--print(Weight)

			FrictionValues[Raycast.Material] =  GetFrictionBetweenMaterial(Properties) * AREA_OF_CONTACT
		end

		return FrictionValues[Raycast.Material]
	end

	return 1
end

return World
