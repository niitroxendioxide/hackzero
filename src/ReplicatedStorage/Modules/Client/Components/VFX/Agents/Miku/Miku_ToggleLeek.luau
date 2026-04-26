---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local Cache = {}
local function Effect(
    Caster: Types.Caster,
    State: string,
    Time: number
): ()
    local Model = Caster:GetModel()
    local LeekModel = Model:FindFirstChild("Leek")


    ---
    if State == 'Enable' then
        if Cache[Caster] or LeekModel.Handle.Transparency == 0 then
            if Cache[Caster] then
                task.cancel(Cache[Caster])
            end

            if Time then
                Cache[Caster] = task.delay(Time, Effect, Caster, 'Disable')
            end

            return
        end

        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.fromRGB(33, 214, 255)
        Highlight.FillTransparency = 0
        Highlight.OutlineColor = Color3.fromRGB(24, 232, 255)
        Highlight.OutlineTransparency = 0
        Highlight.Parent = LeekModel

        LeekModel.Handle.Transparency = 0

        Effects:Tween(Highlight, { 0.25 }, { FillTransparency = 1, OutlineTransparency = 1 })
        Effects:CleanUp(Highlight, 0.5)

        Effects:Emit(LeekModel)

        if Time then
            Cache[Caster] = task.delay(Time, Effect, Caster, 'Disable')
        end
    elseif State == 'Disable' then
        Effects:Emit(LeekModel)
        Effects:Tween(LeekModel.Handle, { 0.1 }, { Transparency = 1 })

        Cache[Caster] = nil
    end
end

return Effect