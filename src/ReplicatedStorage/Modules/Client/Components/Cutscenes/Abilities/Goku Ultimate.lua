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
local Dir = "Characters.Goku.Abilities.Ultimate."
local Settings = require(Client.Packages.Settings)

--
local AgentCache = {
    __Threads = {},
    __Methods = {},
}
local GokuUltimate = CutsceneClass.new("GokuSSJ", 0.967)

GokuUltimate:FilterCameraUsage(function(Agent: AgentTypes.AgentClass)
    if Agent.__Player_Assigned == Players.LocalPlayer then
        return true
    end

    return false
end)

function GokuUltimate:Sequence(Agent: AgentTypes.AgentClass)
    if AgentCache.__Methods[Agent] then
        AgentCache.__Methods[Agent]()
    end

    if AgentCache.__Threads[Agent] then
        task.cancel(AgentCache.__Threads[Agent])
    end

    if Agent.Name ~= 'Goku' then
        return
    end

    GokuUltimate:SetCameraUser(Agent.__Player_Assigned)

    local AgentModel = Agent:GetModel()
    local Appearance = Agent.__Character.__Appearance
    local ModelParts = AgentModel:FindFirstChild("Parts"):FindFirstChild("Head")
    if not ModelParts then
        return
    end

    if GokuUltimate:IsCameraUser() then
        CutsceneEffects:HideHUD(GokuUltimate.__Time)
    end

    local SuperSaiyanAura = Assets.Effects.Agents.Goku.SuperSaiyanAura:Clone()
    GokuUltimate:SetFOV(40)

    GokuUltimate:SetFOV(39, {.4})
    task.delay(.4, function()
        GokuUltimate:SetFOV(30, {.317})

        task.wait(.317)
        GokuUltimate:SetFOV(45, {0.05})
    end)

    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')
    local AgentAnimObj = AnimLib:GetAnim(Dir..'Agent')

    local TrackAnim = AnimLib:Play(AgentModel, AgentAnimObj)
    Agent:AddTrackToState('Attacking', TrackAnim, 1)

    local _ = GokuUltimate:AnimateCamera(AgentModel, CameraAnimObj)

    local BaseHair = ModelParts.BaseHair
    local SSHair = ModelParts.SSHair
    local BaseFace = ModelParts.BaseFace
    local SSFace = ModelParts.SSFace

    task.delay(.35, function()
        EffectsUtil:Tween(BaseHair, {.2, "Quad", nil, nil, true}, {Color = Color3.fromRGB(253, 220, 138)})
    end)

    GokuUltimate:Wait(0.733)
    local SlashEffect = EffectsUtil:Create(Assets.Effects.Agents.Goku.SSJBurst, 2.5)
    SlashEffect:PivotTo(Agent:GetModel():GetPivot())
    EffectsUtil:Emit(SlashEffect)

    if GokuUltimate:IsCameraUser() then
        local CC = Instance.new('ColorCorrectionEffect')
        CC.Saturation = -1.3
        CC.Contrast = 32
        CC.Brightness = 1
        CC.TintColor = Color3.fromRGB(255, 194, 140)
        CC.Parent = Lighting

        EffectsUtil:Tween(CC, {0.1, 'Quad'}, {Brightness = 0, TintColor = Color3.new(1,1,1)})
        EffectsUtil:CleanUp(CC, 0.1)
    end

    EffectsUtil:Weld(SuperSaiyanAura, AgentModel.PrimaryPart)
    SuperSaiyanAura:PivotTo(AgentModel:GetPivot())
    SuperSaiyanAura.Parent = workspace.World.Effects

    if not Settings:Get("AuraEffects", 'Graphics') then
        EffectsUtil:Toggle(SuperSaiyanAura, false, function(Object: Beam | Instance | ParticleEmitter): boolean  
            if Object.Parent.Name == 'Ground' then
                return false
            end

            return true
        end)
    end

    Appearance:EditPartValue(BaseHair, 1)
    Appearance:EditPartValue(SSHair, 0)
    Appearance:EditPartValue(SSFace, 0)
    Appearance:EditPartValue(BaseFace, 1)
    Appearance:EditPartValue(BaseFace.Face, 1)
    Appearance:BindParticles(SuperSaiyanAura)

    --
    local Highlight = Instance.new('Highlight')
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.FillTransparency = 1
    Highlight.OutlineColor = Color3.fromRGB(235, 255, 11)
    Highlight.OutlineTransparency = 0.1
    Highlight.Parent = AgentModel

    AgentCache.__Methods[Agent] = function()
        Appearance:EditPartValue(SSHair, 1)
        Appearance:EditPartValue(BaseHair, 0, not Agent:IsActive())
        Appearance:EditPartValue(SSFace, 1)
        Appearance:EditPartValue(BaseFace, 0, not Agent:IsActive())
        Appearance:EditPartValue(BaseFace.Face, 0, not Agent:IsActive())
        Appearance:UnbindParticles(SuperSaiyanAura)

        EffectsUtil:Toggle(SuperSaiyanAura, false, nil, true)
        EffectsUtil:CleanUp(SuperSaiyanAura, 1)

        EffectsUtil:Tween(Highlight, {.15}, {OutlineTransparency = 1})
        EffectsUtil:CleanUp(Highlight, .15)
    end

    --
    AgentCache.__Threads[Agent] = task.delay(15, AgentCache.__Methods[Agent])
end

return GokuUltimate