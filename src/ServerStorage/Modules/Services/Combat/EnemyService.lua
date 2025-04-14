--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Enemies = require(Shared.Libraries.Enemies)
local Places = require(Shared.Places)
local Signal = require(Shared.Utility.Signal)

local EnemiesDatabase = require(Database.Enemies)
local ServerEnemy = require(ServerStorage.Modules.Classes.Combat.ServerEnemy)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Service = {
	__Limit = 4,
	__CurrentEnemies = 0,
	EnemiesCleared = {} :: Types.Signal<>,
}

function Service:Init()
	if not Places:CanFight() then
		return;
	end

	Service.EnemiesCleared = Signal.new();
end

function Service:LoadEnemies(Player: Player)
	if not Player:HasTag('Ping') then
		repeat task.wait()
		until Player:HasTag('Ping')
	end

	for Id, Enemy in Enemies:GetAll() do
		--local Target = Enemy:GetTarget()

		Replicator:AddEnemy(Id, Enemy, Player)

		Enemy:FindRandomAggro()
		Replicator:PivotEnemy(Id, Enemy.__Movement.__Position, Player)
		Replicator:MoveEnemy(Id, Enemy.__Movement.__Direction, Player)
	end
end

function Service:Spawn(Type: string)
	if not(Service:__CanSpawn()) then return end

	if not EnemiesDatabase:GetEnemyData(Type) and Type ~= "any" then
		return
	end

	if Type == "any" then
		local EnemyNames = EnemiesDatabase:GetAllEnemyNames()

		Type = EnemyNames[math.random(1, #EnemyNames)]
	end

	local Spawns = Service:GetSpawns()
	local RandomSpawn = Spawns[math.random(1, #Spawns)]

	local At = Service:__GenerateLocation(RandomSpawn)
	local Enemy = ServerEnemy.new(At.Position, Type, 60)
	local Key = Service:__Add(Enemy)

	Enemy:Init(Key)

	return Enemy
end

function Service:GetSpawns(): {Instance}
	local WorldFolder = workspace:FindFirstChild('World') :: Folder
	local MapFolder = WorldFolder.Map :: Folder
	local Spawns = MapFolder:FindFirstChild('EnemySpawns')

	return Spawns:GetChildren()
end

--
function Service:__CanSpawn(): boolean
	--if Service.__CurrentEnemies + 1 > Service.__Limit then return false end
	
	if Service.__CurrentEnemies <= 255 then return true end
	
	for key = 0, 255 do
		if Enemies:GetEnemy(key) == nil then
			return true
		end
	end
	
	return false
end

function Service:__Add(Enemy: Types.ServerEnemyClass): ()
	local EnemyKey = Service.__CurrentEnemies
	
	if Service.__CurrentEnemies < 255 then
		Enemies:AddEnemy(EnemyKey, Enemy)
	else
		for key = 0, 255 do
			if Enemies:GetEnemy(EnemyKey) == nil then
				EnemyKey = key
				
				Enemies:AddEnemy(EnemyKey, Enemy)
			end
		end
	end
	
	Service.__CurrentEnemies += 1
	
	Replicator:AddEnemy(EnemyKey, Enemy)
	
	return EnemyKey
end

function Service:__Remove(Enemy: Types.ServerEnemyClass): ()
	local Key = Enemies:RemoveEnemy(Enemy)
	Enemy:Destroy()

	Replicator:RemoveEnemy(Key)
end

function Service:__GenerateLocation(SpawnLocation: BasePart)
	
	local cFrame = SpawnLocation.CFrame
	local Size = SpawnLocation.Size
	
	local RNG = Random.new()
	
	return cFrame * CFrame.new(RNG:NextNumber(-Size.X/2, Size.X/2), -Size.Y/2 + 3.15, RNG:NextNumber(-Size.Z/2, Size.Z/2))
end

return Service
