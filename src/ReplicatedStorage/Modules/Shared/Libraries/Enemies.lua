--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local EnemyLibrary = {
	__Enemies = {},
	__Last_Enemy_Pos = {},
}

function EnemyLibrary:AddEnemy(Id: number, Enemy: Types.EnemyClass | Types.ServerEnemyClass)
	if EnemyLibrary:GetEnemy(Id) ~= nil then
		EnemyLibrary:RemoveEnemy(Id)
	end
	
	EnemyLibrary.__Enemies[Id] = Enemy
end

function EnemyLibrary:RemoveEnemy(EnemyId: number | Types.ServerEnemyClass)
	local Id = EnemyId
	
	if typeof(Id) ~= 'number' then
		local ComparedEnemy = Id
		for key, SavedEnemy in EnemyLibrary:GetAll() do
			if ComparedEnemy == SavedEnemy then
				Id = key
			end
		end

		if typeof(Id) ~= 'number' then return end
	end
	
	EnemyLibrary.__Last_Enemy_Pos[Id] = EnemyLibrary.__Enemies[Id]:GetPivot()
	EnemyLibrary.__Enemies[Id] = nil
	
	return Id
end

function EnemyLibrary:GetEnemy(Id: number): Types.EnemyClass & Types.ServerEnemyClass
	return EnemyLibrary.__Enemies[Id]
end

function EnemyLibrary:GetFromCollider(BasePart: BasePart): Types.EnemyClass?
	for _, Enemy: Types.EnemyClass in self:GetAll() do
		if Enemy:GetCollider() == BasePart then
			return Enemy
		end
	end

	return nil;
end

function EnemyLibrary:GetAll<T>(): T
	return EnemyLibrary.__Enemies
end

function EnemyLibrary:GetEnemyCount()
	local k = 0
	for _ in self:GetAll() do
		k += 1
	end
	
	return k
end

function EnemyLibrary:GetNearestEnemy(
	Point: Vector3, 
	MaxDistance: number, 
	LineOfSight: boolean?, 
	to_Exclude: {}?, 
	filter: ((Enemy: any) -> (number))?
): (number?, Types.EnemyClass?)
	local Distance = MaxDistance or math.huge
	local Selected = nil
	local Exclude = to_Exclude or {}
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.World.Entities:FindFirstChild("Destructibles")}
	Params.FilterType = Enum.RaycastFilterType.Include

	local Options = {}
	for Key, Enemy in EnemyLibrary:GetAll() do
		if table.find(Exclude, Enemy) then
			continue
		end

		local DistanceToEnemy = (Point - Enemy:GetPivot().Position).Magnitude
		if LineOfSight then
			local LookAt = CFrame.lookAt(Point, Enemy:GetPivot().Position)
			local LookAtRay = workspace:Raycast(Point, LookAt.LookVector * DistanceToEnemy, Params)
			if LookAtRay then
				continue
			end
		end

		if typeof(filter) == 'function' then
			if DistanceToEnemy <= MaxDistance then
				Options[Enemy] = filter(Enemy) * DistanceToEnemy
			end
			
			continue
		end

		local WeightedDistance = DistanceToEnemy
		if Enemy.__Appearance and Enemy.__Appearance:GetAddedHeight() > 0 then
			WeightedDistance *= 0.5
		end

		if WeightedDistance < Distance then
			Distance = WeightedDistance
			Selected = Key
		end
	end

	if filter then
		local Chosen, CurrentWeight = next(Options)
		for Enemy, Weight in Options do
			if Weight < CurrentWeight then
				CurrentWeight = Weight
				Chosen = Enemy
			end
		end

		return (if Chosen then Chosen:GetId() else 0), Chosen
	end

	if Selected then
		return Selected, EnemyLibrary:GetEnemy(Selected)
	end

	return 0, nil
end

function EnemyLibrary:GetCameraFirstEnemy(Point: Vector3, MaxDistance: number, to_Exclude: {}?, filter: ((Enemy: any) -> (number))?): (number?, Types.EnemyClass?)
	if not RunService:IsClient() then
		return 0, nil;
	end

	MaxDistance = MaxDistance or math.huge
	local Exclude = to_Exclude or {}
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.World.Entities:FindFirstChild("Destructibles")}
	Params.FilterType = Enum.RaycastFilterType.Include
	
	local Direction = workspace.CurrentCamera.CFrame.LookVector;
	local FovAngle = 120;

	local FlatDirection = vector.normalize(Direction * vector.create(1, 0, 1))
    local HalfFovCos = math.cos(math.rad((FovAngle) * 0.5))

	local Options = {}
	for Key, Enemy in EnemyLibrary:GetAll() do
		if table.find(Exclude, Enemy) then
			continue
		end

		local LookAt = CFrame.lookAt(Point, Enemy:GetPivot().Position)
		local DirectionToEnemy = vector.normalize(LookAt.LookVector * vector.create(1, 0, 1))
		local DistanceToEnemy = (Point - Enemy:GetPivot().Position).Magnitude;
		local DotProd = vector.dot(FlatDirection, DirectionToEnemy);

		if DotProd < HalfFovCos then
			continue
		end

		local LookAtRay = workspace:Raycast(Point, DirectionToEnemy * DistanceToEnemy, Params)
		if LookAtRay then
			continue
		end

		if typeof(filter) == 'function' then
			if DistanceToEnemy <= MaxDistance then
				Options[Enemy] = filter(Enemy) * DistanceToEnemy
			end
			
			continue
		end

		local isAirborne = Enemy.__Appearance and Enemy.__Appearance:GetAddedHeight() > 0

		if DistanceToEnemy < MaxDistance then
			Options[Enemy] = DistanceToEnemy * (1 + (1 - DotProd) * 2) * (isAirborne and 0.75 or 1)
		end
	end

	local Chosen, CurrentWeight = next(Options)
	for Enemy, Weight in Options do
		if Weight < CurrentWeight then
			CurrentWeight = Weight
			Chosen = Enemy
		end
	end

	return (if Chosen then Chosen:GetId() else 0), Chosen
end

function EnemyLibrary:GetHitboxes()
	local List = {}
	for _, Enemy in EnemyLibrary:GetAll() do
		List[Enemy:GetHitbox()] = Enemy
	end

	return List
end


return EnemyLibrary
