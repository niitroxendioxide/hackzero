---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local AuraOffset = CFrame.new(0.081, -0.106, 0.05)
local EffectOffset = CFrame.new(-0.000183105469, -0.0383501053, 0.37184906, 0, 0, -1, 0.00953629613, 0.999954641, 0, 0.999954641, -0.00953629613, 0)
local Cache = {}

return function(Caster: Types.Caster)
    if typeof(Cache[Caster]) == 'function' then
        Cache[Caster]()
        Cache[Caster] = nil

        return
    end

    local AkaAssets = Assets.Chihiro.Aka
    local CasterModel = Caster:GetModel()

    local KatanaModel = CasterModel:FindFirstChild("Katana")
    if not KatanaModel then
        return;
    end

    local ChargeUpEffects = Effects:Create(AkaAssets.StanceAura)
    ChargeUpEffects:PivotTo(CasterModel:GetPivot() * AuraOffset)
    ChargeUpEffects.Anchored = true

    local Ground = Effects:CastMapRaycast(CasterModel:GetPivot().Position, vector.create(0, -100))
    if Ground then
        Effects:RecolorSmoke(Ground, ChargeUpEffects:GetDescendants())
    end

    local KatanaParticleAura = Effects:Create(AkaAssets.KatanaAura)
    KatanaParticleAura:PivotTo(KatanaModel.Blade.CFrame * EffectOffset)
    Effects:Weld(KatanaParticleAura, KatanaModel.Blade)

    local List = {}
    for _, AuraEffect in AkaAssets.StanceSwordAura:GetChildren() do
        local Particle = Effects:Create(AuraEffect, nil, KatanaModel.Blade)
        table.insert(List, Particle)
    end

    Cache[Caster] = function()

        Effects:Toggle(KatanaParticleAura, false)
        Effects:Toggle(ChargeUpEffects, false)

        for _, Particle in List do
            Particle.Enabled = false
            Effects:CleanUp(Particle, 2)
        end

        Effects:CleanUp(ChargeUpEffects, 2)
        Effects:CleanUp(KatanaParticleAura, 2)
    end
end
