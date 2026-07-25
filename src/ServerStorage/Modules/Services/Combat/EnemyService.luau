--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Heap = require(ReplicatedStorage.Modules.Shared.Utility.Heap)
local Types = require(Shared.Types)
local Enemies = require(Shared.Libraries.Enemies)
local Places = require(Shared.Places)
local Signal = require(Shared.Utility.Signal)

local EnemiesDatabase = require(Database.Enemies)
local ServerEnemy = require(ServerStorage.Modules.Classes.Combat.ServerEnemy)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)

--
local Service = {
	__Limit = 240,
	__CurrentEnemies = 1,
	__EnemyCache = {},
	__Tag_Enemies = {},
	__Enemy_Keys = Heap.new(250),
	EnemyDied = {} :: Types.Signal<string>,
	EventEnemiesCleared = {} :: Types.Signal<string>,
}

function Service:Init()
	if not Places:CanFight() then
		return;
	end

	Service.EnemyDied = Signal.new();
	Service.EventEnemiesCleared = Signal.new();
end

function Service:LoadEnemies(Player: Player)
	if not Player:HasTag('Ping') then
		repeat task.wait()
		until Player:HasTag('Ping')
	end

	for Id, Enemy in Enemies:GetAll() do
		--local Target = Enemy:GetTarget()

		local EnemyEffects = Enemy.__Status.__Effects;
		local Buffs = {}
		for _, Effect in EnemyEffects do
			table.insert(Buffs, {Effect.Type, Effect.Value})
		end

		Replicator:AddEnemy(Id, Enemy, Buffs, Player)

		Enemy:FindRandomAggro()
		Replicator:PivotEnemy(Id, Enemy.__Movement.__Position, Player)
		Replicator:MoveEnemy(Id, Enemy.__Movement.__Direction, nil, nil, Player)
	end
end

function Service:Spawn(Type: string, Level: number, Tag: string, Buffs: {{string | number}})
	if not(Service:__CanSpawn()) then return end

	if not EnemiesDatabase:GetEnemyData(Type) and Type ~= "any" then
		return
	end

	if Type == "any" then
		local EnemyNames = EnemiesDatabase:GetAllEnemyNames()

		Type = EnemyNames[math.random(1, #EnemyNames)]
	end

	local Spawn = workspace.World.Map.Triggers:FindFirstChild(Tag)
	if not Spawn then
		local RandomSpawn = Service:GetSpawns()

		Spawn = RandomSpawn[math.random(1, #RandomSpawn)]

		if not Spawn then 
			print('no spawns') 
			return 
		end
	end

	local At = Service:__GenerateLocation(Spawn)
	local Enemy = ServerEnemy.new(At.Position, Type, Level)
	local Key = Service:__Add(Enemy, Buffs)

	Enemy.Died:Once(function()
		Service:__Remove(Enemy, Tag)
	end)

	if Service.__Tag_Enemies[Tag] == nil then
		Service.__Tag_Enemies[Tag] = {}
	end

	table.insert(Service.__Tag_Enemies[Tag], Enemy)

	Enemy:Init(Key)

	return Enemy
end

function Service:GetSpawns(): {Instance}
	local WorldFolder = workspace:FindFirstChild('World') :: Folder
	local MapFolder = WorldFolder.Map :: Folder
	local Spawns = MapFolder:FindFirstChild('EnemySpawns')
	if not Spawns then
		return {}
	end

	return Spawns:GetChildren()
end

function Service:KillAll(Tag: string?)
	if Tag then
		for _, Enemy in Service.__Tag_Enemies[Tag] do
			Enemy:Kill()
		end
	else
		for Tag in Service.__Tag_Enemies do
			for _, Enemy in Service.__Tag_Enemies[Tag] do
				Enemy:Kill()
			end
		end
	end
end

--
function Service:__CanSpawn(): boolean
	return not Service.__Enemy_Keys:isEmpty()
end

function Service:__Add(Enemy: Types.ServerEnemyClass, Buffs: { {string | number} }): ()
	local EnemyKey = Service.__Enemy_Keys:extract()
	if not EnemyKey then
		return
	end

	Enemies:AddEnemy(EnemyKey, Enemy)

	Service.__CurrentEnemies += 1

	table.insert(Service.__EnemyCache, Enemy)

	for _, Buff in Buffs do
		if Buff[1] == 'Affected_Aura' then
			task.delay(.1, function()
				Replicator:Effect("Aura", {EnemyKey}, true)
			end)

			continue
		end

		Enemy:AddEffect({
			Tag = 'EnemyBuff',
			Type = Buff[1],
			Value = Buff[2],
		})
	end

	Replicator:AddEnemy(EnemyKey, Enemy, Buffs)

	return EnemyKey
end

function Service:__Remove(Enemy: Types.ServerEnemyClass, TagOfRemovedEnemy: string): ()
	local Index = table.find(Service.__EnemyCache, Enemy)
	if Index then
		table.remove(Service.__EnemyCache, Index)

		local EnemyKey = Enemy.__EnemyId
		local EventEnemyList = Service.__Tag_Enemies[TagOfRemovedEnemy]
		Service.__CurrentEnemies -= 1

		Service.__Enemy_Keys:insert(EnemyKey)

		Service.EnemyDied:Fire(TagOfRemovedEnemy)

		table.remove(EventEnemyList, table.find(EventEnemyList, Enemy))

		if #EventEnemyList <= 0 then
			Service.EventEnemiesCleared:Fire(TagOfRemovedEnemy)
		end
	end
end

function Service:__GenerateLocation(SpawnLocation: BasePart)
	local cFrame = SpawnLocation.CFrame

	local Size = (SpawnLocation:GetAttribute("AreaSize") or SpawnLocation.Size) :: Vector3
	local BaseOffset = CFrame.new(SpawnLocation:GetAttribute("AreaOffset") or Vector3.new()) :: CFrame

	local RNG = Random.new()

	return (cFrame * BaseOffset) * CFrame.new(RNG:NextNumber(-Size.X/2, Size.X/2), Size.Y/2, RNG:NextNumber(-Size.Z/2, Size.Z/2))
end

return Service
