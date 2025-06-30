--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

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

function EnemyLibrary:GetAll()
	return EnemyLibrary.__Enemies
end

function EnemyLibrary:GetEnemyCount()
	local k = 0
	for _ in self:GetAll() do
		k += 1
	end
	
	return k
end

function EnemyLibrary:GetNearestEnemy(Point: Vector3, MaxDistance: number, LineOfSight: boolean?): (number?, Types.EnemyClass?)
	local Distance = MaxDistance or math.huge
	local Selected = nil
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.World.Entities:FindFirstChild("Destructibles")}
	Params.FilterType = Enum.RaycastFilterType.Include

	for Key, Enemy in EnemyLibrary:GetAll() do
		local DistanceToEnemy = (Point - Enemy:GetPivot().Position).Magnitude
		if LineOfSight then
			local LookAt = CFrame.lookAt(Point, Enemy:GetPivot().Position)
			local LookAtRay = workspace:Raycast(Point, LookAt.LookVector * DistanceToEnemy, Params)
			if LookAtRay then
				continue
			end
		end


		if DistanceToEnemy < Distance then
			Distance = DistanceToEnemy
			Selected = Key
		end
	end

	if Selected then
		return Selected, EnemyLibrary:GetEnemy(Selected)
	end

	return nil, nil
end

function EnemyLibrary:GetHitboxes()
	local List = {}
	for _, Enemy in EnemyLibrary:GetAll() do
		List[Enemy:GetHitbox()] = Enemy
	end

	return List
end


return EnemyLibrary
