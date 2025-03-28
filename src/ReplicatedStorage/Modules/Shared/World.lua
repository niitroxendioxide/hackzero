--
local Plastic = PhysicalProperties.new(Enum.Material.SmoothPlastic)
local AREA_OF_CONTACT = 1.8
local FrictionValues = {}
local World = {
	CharacterAcceleration = 10,
	StepHeight = 1.895,
	
}

function World:GetSpeed()
	return 1
end

function World:GetAirFriction()
	return 20
end

function World:GetMapParams(Overlap: boolean)
	local Params = Overlap and OverlapParams.new() or RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.World.Map}
	Params.FilterType = Enum.RaycastFilterType.Include
	
	return Params
end

function World:GetCollisionParams(Overlap: boolean)
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {workspace.World.Map, workspace.World.Entities.Colliders, workspace.Camera:FindFirstChild('Enemy_Collisions')}
	ParamsNew.FilterType = Enum.RaycastFilterType.Include
	
	return ParamsNew
end

function World:GetColliderParams(Overlap: boolean)
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {workspace.World.Entities.Colliders, workspace.World.Entities.Hitboxes, workspace.Camera:FindFirstChild('Enemy_Collisions')}
	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	return ParamsNew
end

function World:GetEnemyColliderParams(Overlap: boolean)
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {workspace.World.Entities.Colliders, workspace.Camera:FindFirstChild('Enemy_Collisions')}
	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	return ParamsNew
end

local function GetFrictionBetweenMaterial(Material)
	return (Plastic.Friction * Plastic.FrictionWeight + Material.Friction * Material.FrictionWeight) / (Plastic.FrictionWeight + Material.FrictionWeight)
end

function World:GetSurfaceFriction(At: Vector3)
	local Raycast = workspace:Raycast(At, Vector3.yAxis*-25, World:GetMapParams())
	
	if Raycast then
		if not FrictionValues[Raycast.Material] then
			local Properties = PhysicalProperties.new(Raycast.Material)
			local Friction = Properties.Friction
			local Weight = Properties.FrictionWeight
			
			--print(Weight)
			
			FrictionValues[Raycast.Material] =  GetFrictionBetweenMaterial(Properties) * AREA_OF_CONTACT
		end
		
		return FrictionValues[Raycast.Material]
	end
	
	return 1
end

return World
