local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PhysicsService = game:GetService('PhysicsService')
local ServerStorage = game:GetService('ServerStorage')

PhysicsService:RegisterCollisionGroup('Effects')
PhysicsService:RegisterCollisionGroup('Characters')

PhysicsService:CollisionGroupSetCollidable('Characters', 'Characters', false)
PhysicsService:CollisionGroupSetCollidable('Characters', 'Effects', false)
PhysicsService:CollisionGroupSetCollidable('Characters', 'Default', false)

--
local Entities = Instance.new('Folder')
Entities.Name = 'Enemies'
Entities.Parent = workspace:FindFirstChild('Camera')

local Colliders = Instance.new('Folder')
Colliders.Name = 'Enemy_Collisions'
Colliders.Parent = workspace:FindFirstChild('Camera')

local Destructibles = Instance.new('Folder')
Destructibles.Name = 'Destructibles'
Destructibles.Parent = workspace:FindFirstChild('Camera')

local Modules = ServerStorage.Modules
local Ping = ReplicatedStorage:FindFirstChild("Ping") or Instance.new("RemoteFunction")
Ping.Name = 'Ping'
Ping.Parent = ReplicatedStorage

local PingLib = require(ServerStorage.Modules.Libraries.Ping)

Ping.OnServerInvoke = function(Player: Player, Time: number)
	if not Player:HasTag('Ping') then
		Player:AddTag('Ping')
	end

	local Tick = DateTime.now().UnixTimestampMillis
	local Ping = ((Tick-Time) * 2) / 1000

	PingLib:Set(Player, Ping)

	return Tick
end

task.spawn(function()
	for _, Children: Instance in workspace:GetChildren() do
		if Children:IsA('Terrain') or Children:IsA("Folder") or Children:IsA("Camera") or Children:IsA("SpawnLocation") or Children.Name == 'Baseplate' then
			continue
		end

		Children:Destroy()
	end

end)

--
local Framework = require(ReplicatedStorage.Modules.Framework)
local World = workspace:WaitForChild('World');

Framework:Init(ReplicatedStorage.Modules.Shared.Database, ServerStorage.Modules.Libraries, {Modules.Services, true})

World.Effects:ClearAllChildren()