---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local ForgeVFX = require(ReplicatedStorage.Packages.ForgeVFX)

local ChargeOffset = CFrame.new(0.432, -1.001, -1.74)
local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local _Args = {...}

    local KakashiVfx = Assets.Effects.Agents.Kakashi
    local Model = Caster:GetModel()
    
    if State == 'Charge' then
        local ChargeVFX = Effects:Create(KakashiVfx.ChargingRaikiri2, 5)
        ChargeVFX:PivotTo(Model:GetPivot() * ChargeOffset)

        task.delay(0.15, function()
            for i = 1, 2 do
                local NewShockwave = Effects:Create(Effects.General.Shockwaves.SmallGroundWind, 2.25)
                NewShockwave:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, -2.5 + Effects:Random(-0.25, 0.25), -1.7))
                ForgeVFX.emit(Effects:Random(1, 1.3), NewShockwave)
            end
        end)
        
        Cache[Caster] = function()
            Effects:Toggle(ChargeVFX, false)
            Effects:CleanUp(ChargeVFX, 0.5)
        end
    else
        const _ = Cache[Caster] and Cache[Caster]()
    end
end