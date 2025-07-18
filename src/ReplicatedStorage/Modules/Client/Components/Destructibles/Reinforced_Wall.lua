--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.Destructibles
local Client = ReplicatedStorage.Modules.Client
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ClientDestructible = require(Client.Classes.ClientDestructible)

local ReinforcedWallClass = ClientDestructible.new("Reinforced_Wall")
local Rng = Random.new()

ReinforcedWallClass:OnCreate(function(Object)
    local CrystalBase = Assets:FindFirstChild('Crystal')
    if not CrystalBase then
        return
    end

    local CFPos = Object.CFrame
    local ReinforcedWall = Assets.Reinforced_Wall_Model:Clone()
    ReinforcedWall:PivotTo(CFPos)
    ReinforcedWall.Parent = ClientDestructible.Parent

    Object.Cache.Model = ReinforcedWall
end)

ReinforcedWallClass:OnDestroy(function(Object)
    local Model: Model = Object.Cache.Model;
    if not Model then return end

    Model.Parent = workspace.World.Effects

    for _, Wall: Instance in Model:GetChildren() do
        if not Wall:IsA("BasePart") then
            continue
        end
        Wall.Anchored = false
        Wall.CanCollide = true
        Wall.CollisionGroup = "Effects"

        local Time = Rng:NextNumber(0.15, 0.25)
        local Vel = Rng:NextUnitVector()
        local BodyVel = Instance.new('BodyVelocity')
        local BodyAngVel = Instance.new('BodyAngularVelocity')
        BodyVel.MaxForce = Vector3.one*math.huge
        BodyVel.Velocity = Vector3.new(Vel.X, math.abs(Vel.Y), Vel.Z)  * Rng:NextInteger(15, 30)
        BodyAngVel.AngularVelocity = Rng:NextUnitVector() * Rng:NextInteger(7, 22)
        BodyAngVel.MaxTorque = Vector3.one*math.huge

        BodyVel.Parent = Wall
        BodyAngVel.Parent = Wall

        Effects:MultiClean({BodyVel, BodyAngVel}, Time)
        Effects:Tween(Wall, {Rng:NextNumber(.7, 1.4)}, {Size = Vector3.zero})
    end

    Effects:CleanUp(Model, 2)
end)

ReinforcedWallClass:OnHit(function(Object)
    local Model = Object.Cache.Model :: Model?
    if not Model then return end
end)

return ReinforcedWallClass
