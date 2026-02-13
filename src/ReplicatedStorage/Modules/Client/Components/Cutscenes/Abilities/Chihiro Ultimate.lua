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

    if Ultimate:IsCameraUser() then
        local DepthOfField = Instance.new('DepthOfFieldEffect')
        DepthOfField.Parent = Lighting

        EffectsUtil:Tween(DepthOfField, {0.2, 'Quad'}, {FarIntensity = 1, FocusDistance = 0.01, InFocusRadius = 8, NearIntensity = 0})
        EffectsUtil:CleanUp(DepthOfField, 1.22)
    end

    local ChargeUpEffects = EffectsUtil:Create(AkaAssets.UserAura, 2)
    ChargeUpEffects:PivotTo(CasterModel:GetPivot())

    EffectsUtil:Tween(ChargeUpEffects.PaintSplatter, { 1.1, 'Sine', 'In' }, {TimeScale = 0})

    Ultimate:Wait(1.1)
    ChargeUpEffects:Destroy()

    EffectsUtil:ShakeCamera("BlowUp")

    local ReleaseSlashVFX = EffectsUtil:Create(AkaAssets.MainSlash, 2)
    ReleaseSlashVFX:PivotTo(CasterModel:GetPivot() * CFrame.new(0, 2.5, 0))
    EffectsUtil:Emit(ReleaseSlashVFX)

    for m = 0, 0 do
        local Angle = m * math.pi;
        local CircleSlash = EffectsUtil:Create(AkaAssets.CircularSlash, 2)
        CircleSlash:PivotTo(CasterModel:GetPivot() * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, Angle, 0))
        CircleSlash:ScaleTo(0.001)

        EffectsUtil:TweenModel(CircleSlash, 1, 0.4, 'Sine', 'Out')
        
        for _, Beam: Beam in CircleSlash:GetChildren() do
            if Beam:IsA("BasePart") then
                EffectsUtil:Tween(Beam, { 0.85, 'Quart' }, { CFrame = Beam.CFrame * CFrame.Angles(0, -math.pi * 0.75, 0) })

                continue
            end
        end
        

        task.delay(0.2, function()
            for _, Beam: Beam in CircleSlash:GetDescendants() do
                if not Beam:IsA('Beam') then
                    continue
                end

                if Beam.Name == 'Wind' then
                    EffectsUtil:FadeOutBeams(Beam, { EffectsUtil:Random(0.75, 1.25), 'Quad' })
                else
                    EffectsUtil:Tween(Beam, { EffectsUtil:Random(0.175, 0.275), 'Quad' }, {Width0 = 0, Width1 = 0})
                end
            end

        end)
    end

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

    local WindMeshes = AkaAssets.Wind:GetChildren()
    for i = 1, 5 do
        local WindMesh = EffectsUtil:Create(WindMeshes[math.random(1, #WindMeshes)], 25)
        WindMesh:PivotTo(CasterModel:GetPivot() * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.pi * 0.5) * CFrame.Angles(EffectsUtil:Random(-math.pi, math.pi), 0, 0))
        
        EffectsUtil:Tween(WindMesh, { 0.8, 'Sine' }, { CFrame = WindMesh.CFrame * CFrame.new(-1, 0, 0) * CFrame.Angles(EffectsUtil:Random(-math.pi * 0.25, math.pi * 0.25), 0, 0) })
        EffectsUtil:Tween(WindMesh.Mesh, { 0.75, 'Quart' }, { Scale = WindMesh.Mesh.Scale * EffectsUtil:Random(0.75, 1.5) })
        EffectsUtil:Tween(WindMesh.Decal, { EffectsUtil:Random(0.6, 0.7), 'Sine' }, { Transparency = 1 })

        WindMesh.Mesh.Scale *= vector.create(1.5, 0.1, 0.1)
    end
end

return Ultimate