---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client


local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
local AnimLibrary = require(Client.Libraries.Animation)

---
local Threads = {}
local Cache = {}
return function(
    TargetId: number,
    Time: number,
    IsFanState: boolean
): ()
    local Target = Enemies:GetEnemy(TargetId)
    local MikuAssets = Assets.Miku
    local Model = Target:GetModel()
    local AuraEffect = IsFanState and 'DancingAura' or 'SlowedAura'

    if Cache[Model] then
        Cache[Model](true)
    else
        local Explosion = Effects:Create(MikuAssets.IceExplosion, 3)
        Explosion:PivotTo(Model:GetPivot())

        Effects:Emit(Explosion, true)
    end

    if Threads[Model] then
        task.cancel(Threads[Model])
        Threads[Model] = nil
    end

    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.fromRGB(94, 255, 244)
    Highlight.OutlineColor = Color3.fromRGB(8, 255, 218)
    Highlight.OutlineTransparency = 0.5
    Highlight.FillTransparency = 0.9
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.Parent = Model

    local AuraSlow = Effects:Create(MikuAssets[AuraEffect], Time + 3)
    AuraSlow:PivotTo(Model:GetPivot())
    Effects:Weld(AuraSlow, Model.PrimaryPart)

    local AnimObject = AnimLibrary:GetAnim("Characters.Miku.Abilities.Special.DanceEnemy")
    local Animation = IsFanState and AnimLibrary:Play(Model, AnimObject)

    Cache[Model] = function(fast: boolean)
        Effects:Toggle(AuraSlow, false)
        if fast then
            Highlight:Destroy()
        else
            Effects:Tween(Highlight, { 0.3 }, { OutlineTransparency = 1, FillTransparency = 1 })
            Effects:CleanUp(Highlight, .3)
        end

        if Animation then
            Animation:Stop(.25)
        end

        Effects:CleanUp(AuraSlow, 1.5)
        Cache[Model] = nil
    end
    Threads[Model] = task.delay(Time, Cache[Model])
end