---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLibrary = require(Client.Libraries.Effects)

---
local Cache = {}
return function(
    Caster: Types.Caster,
    State: string
): ()
    local MikuAssets = Assets.Miku

    ---
    if State == 'Enable' then
        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.fromRGB(33, 214, 255)
        Highlight.FillTransparency = 0.75
        Highlight.OutlineColor = Color3.fromRGB(24, 232, 255)
        Highlight.OutlineTransparency = 0
        Highlight.Parent = Caster:GetModel()
        Highlight.Name = "mikuhighlightsing"

        local Aura = Effects:Create(MikuAssets.SingingAura)
        Aura.CFrame = Caster:GetModel():GetPivot()
        Effects:Weld(Aura, Caster:GetModel().PrimaryPart)
        EffectsLibrary:Play("Miku_ToggleLeek", Caster, "Enable")

        local MikuSinging = Effects:Create(MikuAssets.SpecialAuraMusic)
        MikuSinging:ScaleTo(0.001)
        MikuSinging:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.4, 0))
        Effects:Weld(MikuSinging.Main, Caster:GetModel().PrimaryPart)
        Effects:TweenModel(MikuSinging, 1, 0.25, 'Quart')

        Cache[Caster] = function()
            Effects:CleanUp(Aura, 2)
            Effects:Toggle(Aura, false)

            Effects:Toggle(MikuSinging.Main.Aura, false)
            Effects:CleanUp(MikuSinging, 2)
            for _, Beam in MikuSinging:GetDescendants() do
                if Beam:IsA("Beam") then
                    Effects:FadeOutBeams(Beam, { 0.35 })
                end
            end
        end
    elseif State == 'Disable' then
        EffectsLibrary:Play("Miku_ToggleLeek", Caster, "Enable", 1)

        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

        local Highlight = Caster:GetModel():FindFirstChild("mikuhighlightsing")
        if Highlight then
            Effects:Tween(Highlight, { 0.3 }, {FillTransparency = 1, OutlineTransparency = 1})
            Effects:CleanUp(Highlight, 1)
        end
    end
end