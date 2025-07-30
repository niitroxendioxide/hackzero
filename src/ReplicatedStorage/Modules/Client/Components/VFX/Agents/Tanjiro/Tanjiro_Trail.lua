---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets.Effects
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)

local Cache = {}

---
return function(Caster: Types.AgentClass, Time: number): ()
    local Model = Caster:GetModel()
    local HasSword = Model:FindFirstChild("Sword")
    if not HasSword then return end

    local HasTrail = Model.Sword:FindFirstChild("Blade"):FindFirstChildOfClass("Trail")
    if not HasTrail then
        local Trail = Assets.Agents.Tanjiro.TanjiroTrail:Clone()

        for _, p in Trail:GetChildren() do
            p.Parent = Model.Sword:FindFirstChild("Blade")
        end
    end

    if Cache[Caster] then
        task.cancel(Cache[Caster])
    end

    for _, Trail in Model.Sword.Blade:GetChildren() do
        if Trail:IsA("Trail") then
            Trail.Enabled = true
        end
    end

    Cache[Caster] = task.delay(Time, function()
         Cache[Caster] = nil

        for _, Trail in Model.Sword.Blade:GetChildren() do
            if Trail:IsA("Trail") then
                Trail.Enabled = false
            end
        end

    end)
end