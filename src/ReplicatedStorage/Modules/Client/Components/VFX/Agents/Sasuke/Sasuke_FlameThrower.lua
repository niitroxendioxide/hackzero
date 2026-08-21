---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
local Library = require(Client.Libraries.Effects)

---
local Cache = {}

---
return function(Caster: Types.AgentClass, State: boolean): ()
    local SasukeVFX = Assets.Effects.Agents.Sasuke
    local CasterModel = Caster:GetModel()

    if State == false or Cache[Caster] then
        if Cache[Caster] then
            Cache[Caster]()
        end

        return
    end

    ---
    local FlamethrowerVFX = Effects:Create(SasukeVFX.FlamethrowerVFX)
    Effects:Toggle(FlamethrowerVFX, true)
    Effects:RecolorSmoke(Effects:CastMapRaycast((CasterModel:GetPivot() * CFrame.new(0, 0, -5)).Position, vector.create(0, -50)), FlamethrowerVFX:GetDescendants())

    local Thread = task.spawn(function()
        while true do
            local Head = CasterModel:FindFirstChild('Head')
            if not Head then
                break
            end

            local BasePos = (Head.CFrame * CFrame.new(-0.008, -0.182, -0.601)).Position
            FlamethrowerVFX:PivotTo(CFrame.lookAlong(BasePos, Caster:GetPivot().LookVector))

            task.wait()
        end
    end)
    Cache[Caster] = function()
        Effects:Toggle(FlamethrowerVFX, false)
        Effects:CleanUp(FlamethrowerVFX, 2)
        
        task.cancel(Thread)
        Cache[Caster] = nil
    end
end