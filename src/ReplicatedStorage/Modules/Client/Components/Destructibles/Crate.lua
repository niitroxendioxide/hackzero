local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Destructibles
local Client = ReplicatedStorage.Modules.Client
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ClientDestructible = require(Client.Classes.ClientDestructible)

local CrateObjClass = ClientDestructible.new("Crate")

CrateObjClass:OnCreate(function(Object)
    local LootCrateBase = Assets:FindFirstChild('LootCrate')
    if not LootCrateBase then
        return
    end

    local CFPos = CFrame.new(Object.Position) * CFrame.new(0, 1.75, 0) * CFrame.Angles(0, Effects:Random(-math.pi, math.pi), 0)
    local Model = LootCrateBase:Clone();
    Model:PivotTo(CFPos);
    Model.Parent = ClientDestructible.Parent;

    Object.Cache.Model = Model;
end)

CrateObjClass:OnDestroy(function(Object)
    local Model: Model = Object.Cache.Model;
    if not Model then return end

    Object.Collider.Transparency = 0

    Effects:Tween(Object.Cache.Model, {.1}, {Transparency = 1})
    Effects:Emit(Object.Cache.Model, true);

    Effects:CleanUp(Object.Cache.Model, 2)
end)

return CrateObjClass
