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
Entities.Parent = workspace.Camera

local Entities = Instance.new('Folder')
Entities.Name = 'Enemy_Collisions'
Entities.Parent = workspace.Camera

local Modules = ServerStorage.Modules

ReplicatedStorage.Ping.OnServerInvoke = function(Player: Player)
	if not Player:HasTag('Ping') then
		Player:AddTag('Ping')
	end
	
	return tick()
end

--
local Framework = require(ReplicatedStorage.Modules.Framework)

Framework:Init(ReplicatedStorage.Modules.Shared.Database, Modules.Services)

workspace.World.Effects:ClearAllChildren()