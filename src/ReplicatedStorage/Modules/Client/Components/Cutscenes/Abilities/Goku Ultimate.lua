--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--
local World = workspace:FindFirstChild("World")
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets

local Classes = Client.Classes

local Types = require(Shared.Types)
local EffectsUtil = require(Shared.Utility.Effects)
local CutsceneClass = require(Classes.Cutscene)
local CutsceneEffects = require(Client.Libraries.CutsceneEffects)
local AnimLib = require(Client.Libraries.Animation)
local Dir = "Characters.Goku.Abilities.Ultimate."

--
local AgentCache = {}
local GokuUltimate = CutsceneClass.new("GokuSSJ", 0.967)

function GokuUltimate:Sequence(Agent: Types.AgentClass)
    if AgentCache[Agent] then
        AgentCache[Agent]()
    end

    local AgentModel = Agent:GetModel()
    local Appearance = Agent.__Character.__Appearance
    local ModelParts = AgentModel:FindFirstChild("Parts"):FindFirstChild("Head")
    if not ModelParts then
        return
    end

    CutsceneEffects:HideHUD(GokuUltimate.__Time)
    local SuperSaiyanAura = Assets.Effects.Agents.Goku.SuperSaiyanAura:Clone()


    local CameraAnimObj = AnimLib:GetAnim(Dir..'Camera')
    local AgentAnimObj = AnimLib:GetAnim(Dir..'Agent')

    AnimLib:Play(AgentModel, AgentAnimObj)
    local _ = GokuUltimate:AnimateCamera(AgentModel, CameraAnimObj)

    local BaseHair = ModelParts.BaseHair
    local SSHair = ModelParts.SSHair
    local BaseFace = ModelParts.BaseFace
    local SSFace = ModelParts.SSFace

    task.delay(.35, function()
        EffectsUtil:Tween(BaseHair, {.2, "Quad", nil, nil, true}, {Color = Color3.fromRGB(253, 220, 138)})
    end)

    GokuUltimate:Wait(0.783)
    local CC = Instance.new('ColorCorrectionEffect')
    CC.Saturation = 0.75
    CC.Contrast = 0.75
    CC.Brightness = 0.75
    CC.TintColor = Color3.fromRGB(255, 194, 140)
    CC.Parent = Lighting

    EffectsUtil:Tween(CC, {0.225, 'Quad'}, {Contrast = 0, Saturation = 0, Brightness = 0, TintColor = Color3.new(1,1,1)})

    EffectsUtil:Weld(SuperSaiyanAura, AgentModel.PrimaryPart)
    SuperSaiyanAura:PivotTo(Agent:GetPivot())
    SuperSaiyanAura.Parent = workspace.World.Effects

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

    AgentCache[Agent] = function()
        BaseHair.Transparency = 1
        SSHair.Transparency = 0

        Appearance:EditPartValue(SSHair, 1)
        Appearance:EditPartValue(BaseHair, 0)
        Appearance:EditPartValue(SSFace, 1)
        Appearance:EditPartValue(BaseFace, 0)
        Appearance:EditPartValue(BaseFace.Face, 0)
        Appearance:UnbindParticles(SuperSaiyanAura)

        EffectsUtil:Toggle(SuperSaiyanAura, false, nil, true)
        EffectsUtil:CleanUp(SuperSaiyanAura, 1)

        EffectsUtil:Tween(Highlight, {.15}, {OutlineTransparency = 1})
        EffectsUtil:CleanUp(Highlight, .15)
    end

    --
    task.delay(10, AgentCache[Agent])
end

return GokuUltimate