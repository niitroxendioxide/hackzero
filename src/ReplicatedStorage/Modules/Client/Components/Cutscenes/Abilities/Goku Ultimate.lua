--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

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

--
local AgentCache = {
    __Threads = {},
    __Methods = {},
}
local GokuUltimate = CutsceneClass.new("GokuSSJ", 0.967)

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

    AnimLib:Play(AgentModel, AgentAnimObj)
    local _ = GokuUltimate:AnimateCamera(AgentModel, CameraAnimObj)

    local BaseHair = ModelParts.BaseHair
    local SSHair = ModelParts.SSHair
    local BaseFace = ModelParts.BaseFace
    local SSFace = ModelParts.SSFace

    task.delay(.35, function()
        EffectsUtil:Tween(BaseHair, {.2, "Quad", nil, nil, true}, {Color = Color3.fromRGB(253, 220, 138)})
    end)

    GokuUltimate:Wait(0.733)
    if GokuUltimate:IsCameraUser() then
        local CC = Instance.new('ColorCorrectionEffect')
        CC.Saturation = 0.75
        CC.Contrast = 0.75
        CC.Brightness = 0.75
        CC.TintColor = Color3.fromRGB(255, 194, 140)
        CC.Parent = Lighting

        EffectsUtil:Tween(CC, {0.225, 'Quad'}, {Contrast = 0, Saturation = 0, Brightness = 0, TintColor = Color3.new(1,1,1)})
    end

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

    AgentCache.__Methods[Agent] = function()
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
    AgentCache.__Threads[Agent] = task.delay(10, AgentCache.__Methods[Agent])
end

return GokuUltimate