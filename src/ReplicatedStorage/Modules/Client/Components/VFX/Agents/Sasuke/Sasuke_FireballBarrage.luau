


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Library = require(Client.Libraries.Effects)


---
local Rng = Random.new()

---
return function(
    Caster: Types.Caster
): ()
    --
    local SasukeVFX = Assets.Sasuke
    local Offset = CFrame.new(0, 0, -9)

    local Size = vector.create(12, 12, 16)
    
    local Time = 0
    while (Time < 0.35) do
        Time += Effects:Wait(1 / 24)

        for i = 1, Effects:RandomInt(2, 3) do
            local Z = Effects:Random(-Size.Z/2, Size.Z/2)
            local X = Effects:Random(-Size.X/1.65, Size.X/1.65) * (1 + (Z/Size.Z/2) * 0.33)
            local NewPos = Caster:GetPivot() * Offset * CFrame.new(X, 0, Z)

            local Floor = Effects:CastMapRaycast(NewPos, vector.create(0, -100))
            if Floor then
                local NewEffect = Effects:Create(SasukeVFX.Assist.GroundVFX, 2)
                NewEffect.CFrame = CFrame.lookAlong(Floor.Position, Floor.Normal)

                Effects:Emit(NewEffect, true)
            end
        end
    end
end