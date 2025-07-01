---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Caster: Types.GenericClass, Data: {Color: Color3?})
    Data = Data or {}
	local Model = Caster:GetModel()

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillTransparency = 0
    Highlight.FillColor = Data.Color or Color3.new(1,1,1)
    Highlight.OutlineColor = Highlight.FillColor
    Highlight.OutlineTransparency = 0
    Highlight.Parent = Model

    Effects:Tween(Highlight, {.25}, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, .35)
end
