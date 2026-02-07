--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

--
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local Classes = Client.Classes

local AgentTypes = require(Shared.Types.Agents)
local EffectsUtil = require(Shared.Utility.Effects)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)
local Dir = "Characters.Chihiro.Abilities.Ultimate."

--
local EffectOffset = CFrame.new(-0.000183105469, -0.0383501053, 0.37184906, 0, 0, -1, 0.00953629613, 0.999954641, 0, 0.999954641, -0.00953629613, 0)
local Ultimate = CutsceneClass.new("ChihiroUltimate", 1.1)

Ultimate:FilterCameraUsage(function(Agent: AgentTypes.AgentClass)
    if Agent.__Player_Assigned == Players.LocalPlayer then
        return true
    end

    return false
end)

function Ultimate:Sequence(Agent: AgentTypes.AgentClass)
    if Agent.Name ~= 'Chihiro' then
        return
    end

    local AkaAssets = Assets.Effects.Agents.Chihiro.Aka

    Ultimate:SetCameraUser(Agent.__Player_Assigned)

    local CasterModel = Agent:GetModel()
    if Ultimate:IsCameraUser() then
        CutsceneEffects:HideHUD(Ultimate.__Time)
    end

    Ultimate:SetFOV(45)

    Ultimate:SetFOV(25, {.9, 'Sine'})
    task.delay(.9, function()
        Ultimate:SetFOV(60, {.216, 'Sine', 'In'})
    end)


    local KatanaModel = CasterModel:FindFirstChild("Katana")
    if not KatanaModel then
        return;
    end
    local Highlight = Instance.new('Highlight')
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillTransparency = 1
    Highlight.OutlineTransparency = 1
    Highlight.FillColor = Color3.fromRGB(255, 110, 110)
    Highlight.OutlineColor = Color3.fromRGB(255, 110, 110)
    Highlight.Parent = KatanaModel

    EffectsUtil:CleanUp(Highlight, 2)
    EffectsUtil:Tween(Highlight, { .25, 'Quad' }, { FillTransparency = 0.36, OutlineTransparency = 0 })
    
    for _, AuraEffect in AkaAssets.Aura:GetChildren() do
        EffectsUtil:Create(AuraEffect, 2, KatanaModel.Blade)
    end

    --[[local ChargeUpEffects = EffectsUtil:Create(AkaAssets.UserAura, 2)
    ChargeUpEffects:PivotTo(CasterModel:GetPivot())]]

    local KatanaParticleAura = EffectsUtil:Create(AkaAssets.KatanaAura, 2)
    KatanaParticleAura:PivotTo(KatanaModel.Blade.CFrame * EffectOffset)
    EffectsUtil:Weld(KatanaParticleAura, KatanaModel.Blade)

    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')

    local _ = Ultimate:AnimateCamera(CasterModel, CameraAnimObj)

    Ultimate:Wait(1.1)
    EffectsUtil:Tween(Highlight, { .25, 'Quad' }, { FillTransparency = 1, OutlineTransparency = 1 })
    EffectsUtil:Toggle(KatanaParticleAura, false)
    EffectsUtil:Toggle(KatanaModel.Blade, false)

    if Ultimate:IsCameraUser() then
        local CC = Instance.new('ColorCorrectionEffect')
        CC.Saturation = -1.3
        CC.Contrast = 25
        CC.Parent = Lighting

        EffectsUtil:Tween(CC, {0.12, 'Quad'}, {Contrast = 0})
        EffectsUtil:CleanUp(CC, 0.12)
    end
end

return Ultimate