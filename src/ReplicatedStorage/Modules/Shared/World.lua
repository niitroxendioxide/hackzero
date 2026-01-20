local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Plastic = PhysicalProperties.new(Enum.Material.SmoothPlastic)
local AREA_OF_CONTACT = 1.8
local FrictionValues = {} :: {number}
local World = {
	CharacterAcceleration = 10,
	StepHeight = 1.895,
	CurrentSpeed = 1,
	EndScreenMode = false,
	TweenThread = nil,
	IsTweening = false,
}

local WorldFolder = workspace:WaitForChild('World')

function World:GetSpeed(): number
	return World.CurrentSpeed;
end

function World:SetSpeed(Value: number)
	World.CurrentSpeed = Value;
end

function World:SetEndScreenMode(State: boolean)
	World.EndScreenMode = State
end

function World:IsEndScreenMode(): boolean
	return World.EndScreenMode
end

function World:TweenSpeed(ToValue: number, Time: number)
	if World.TweenThread then
		task.cancel(World.TweenThread)
	end
	
	local InitialSpeed = World.CurrentSpeed;

	World.TweenThread = task.spawn(function()
		World.IsTweening = true
		local InitTimeFrame = os.clock();
		local Value = 0;

		while os.clock() - InitTimeFrame <= Time do
			local Delta = task.wait();
			Value += Delta / Time

			local TweenValue = TweenService:GetValue(Value, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			local Lerp = math.lerp(InitialSpeed, ToValue, TweenValue);

			World.CurrentSpeed = Lerp;
		end
		World.IsTweening = false
	end)

end

function World:GetAirFriction(): number
	return 7
end

function World:GetMapParams(Overlap: boolean?, Groups: {[{BasePart}]: boolean?}?): OverlapParams | RaycastParams
	local List = {WorldFolder.Map, Workspace:FindFirstChild("Baseplate")}
	for Obj in (Groups or {}) :: {} do
		table.insert(List, Obj)
	end

	local Params = Overlap and OverlapParams.new() or RaycastParams.new()
	Params.FilterDescendantsInstances = List
	Params.FilterType = Enum.RaycastFilterType.Include

	return Params
end

function World:GetEntityMapParams(Overlap: boolean?): OverlapParams | RaycastParams
	local Params = Overlap and OverlapParams.new() or RaycastParams.new()
	Params.FilterDescendantsInstances = {
		WorldFolder.Map,
		workspace.Camera:FindFirstChild("Area_Colliders"),
	}
	Params.FilterType = Enum.RaycastFilterType.Include

	return Params
end

function World:GetCollisionParams(Overlap: boolean?, Groups: {}?): OverlapParams | RaycastParams
	local List = {WorldFolder.Map}
	for Obj in (Groups or {}) :: {} do
		table.insert(List, Obj)
	end

	local Camera = workspace:FindFirstChild('Camera') :: Camera
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {
		List,
		WorldFolder.Entities:FindFirstChild("Destructibles"),
		WorldFolder.Entities.Colliders, Camera:FindFirstChild('Enemy_Collisions'),
		Camera:FindFirstChild("Destructibles"),
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

function World:GetAgentColliderParams(Overlap: boolean?, AllCharacters: {}): OverlapParams | RaycastParams
	local Camera = workspace:FindFirstChild('Camera') :: Camera
	local ParamsNew = Overlap and OverlapParams.new() or RaycastParams.new()
	ParamsNew.FilterDescendantsInstances = {}
	ParamsNew.FilterType = Enum.RaycastFilterType.Include

	for _, AgentCharacter in AllCharacters do
		table.insert(ParamsNew.FilterDescendantsInstances, AgentCharacter:GetHitbox())
	end

	return ParamsNew
end


local function GetFrictionBetweenMaterial(Material)
	return (Plastic.Friction * Plastic.FrictionWeight + Material.Friction * Material.FrictionWeight) / (Plastic.FrictionWeight + Material.FrictionWeight)
end

function World:GetSurfaceFriction(At: Vector3): number
	local Params = World:GetMapParams(false, {}) :: RaycastParams
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
