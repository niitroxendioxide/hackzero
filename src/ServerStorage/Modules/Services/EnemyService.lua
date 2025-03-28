--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local ClockUtil = require(Shared.Utility.Clock)
local BufferUtil = require(Shared.Utility.Buffer)
local GameEnum = require(Shared.GameEnum)
local Enemies = require(Shared.Libraries.Enemies)

local ServerEnemy = require(ServerStorage.Modules.Classes.ServerEnemy)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Service = {
	__Limit = 4,
	__CurrentEnemies = 0,
}

local Enemy_Opts = {'Saiyan','Template'}

function Service:Init()
	ClockUtil:ThreadLoop(1, function(Delta: number)
		
		if Enemies:GetEnemyCount() < Service.__Limit then
			Service:Spawn(Enemy_Opts[math.random(1, #Enemy_Opts)])
		end
		
	end)
	
end

function Service:LoadEnemies(Player: Player)
	if not Player:HasTag('Ping') then
		repeat task.wait() until Player:HasTag('Ping')
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
	
	local Spawns = Service:GetSpawns()
	local RandomSpawn = Spawns[math.random(1, #Spawns)]
	
	local At = Service:__GenerateLocation(RandomSpawn)
	local Enemy = ServerEnemy.new(At.Position, Type, 60)
	local Key = Service:__Add(Enemy)
	
	Enemy:Init(Key)
	
	return 
end

function Service:GetSpawns()
	local World = workspace.World.Map
	local Spawns = World:FindFirstChild('EnemySpawns')

	return Spawns:GetChildren()
end

--
function Service:__CanSpawn(): boolean
	--if Service.__CurrentEnemies + 1 > Service.__Limit then return false end
	
	if Service.__CurrentEnemies <= 255 then return true end
	
	for key = 0, 255 do
		if Enemies:Get(key) == nil then
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
			if Enemies:Get(EnemyKey) == nil then
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
