---
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Library = require(Client.Libraries.Effects)

--- Saved stuff

---
return function(
    Caster: Types.Caster,
    Casterpivot: CFrame
): ()
    local ChihiroAssets = Assets.Chihiro

    Library:Play("Afterimage", Caster)

    ---
    local Highlight = Instance.new("Highlight")
    Highlight.Parent = Caster:GetModel()
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillColor = Color3.new()
    Highlight.FillTransparency = -1.5
    Highlight.OutlineColor = Color3.new(1, 1, 1)
    Highlight.OutlineTransparency = 1

    local newCorrection = Instance.new("ColorCorrectionEffect")
    newCorrection.Saturation = -1.3
    newCorrection.Contrast = -2
    newCorrection.Brightness = 0.05
    newCorrection.Parent = Lighting

    Effects:Tween(newCorrection, { 1 / 12 }, { Contrast = -2, Saturation = 0 })

    Effects:CleanUp(newCorrection, 1 / 12)
    Effects:CleanUp(Highlight, 1 / 12)

    ---
    local DashEffect = Effects:Create(ChihiroAssets.DashAssist, 3) 
    DashEffect:PivotTo(Casterpivot * CFrame.new(0, 0, -16))

    for _, Beam in DashEffect.Beam:GetDescendants() do
        if Beam:IsA("Beam") then
            Effects:FadeOutBeams(Beam, { Effects:Random(0.4, 0.6), 'Quad' })
            Effects:Tween(Beam, { Effects:Random(0.4, 0.75) }, { TextureSpeed = 0 })
        elseif Beam:IsA('Attachment') then
            local AttPos = Beam.Position;
            if AttPos.Z > 0 then
                continue
            end

            Beam.Position = vector.create(1, 1, 0)
            Effects:Tween(Beam, {0.25, 'Quad'}, {Position = AttPos})
        end
    end

    Effects:RecolorToGroundColor(Casterpivot.Position, DashEffect.Ground:GetChildren())
    Effects:Emit(DashEffect, true)
end