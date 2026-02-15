---
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
   local DashEffect = Effects:Create(ChihiroAssets.DashAssist, 3) 
   DashEffect:PivotTo(Casterpivot * CFrame.new(0, 0, -16))

    for _, Beam in DashEffect.Beam:GetDescendants() do
        if Beam:IsA("Beam") then
            Effects:FadeOutBeams(Beam, { Effects:Random(0.3, 0.6), 'Quad' })
            Effects:Tween(Beam, { Effects:Random(0.4, 0.75) }, { TextureSpeed = 0 })
        end
    end

   Effects:Emit(DashEffect, true)
end