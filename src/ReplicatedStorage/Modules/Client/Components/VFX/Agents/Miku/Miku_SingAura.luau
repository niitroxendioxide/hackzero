---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLibrary = require(Client.Libraries.Effects)

---
local Cache = {}
return function(
    Caster: Types.Caster,
    State: string,
    IsEx: boolean
): ()
    local MikuAssets = Assets.Miku
    local CasterModel = Caster:GetModel()

    ---
    if State == 'Enable' then
        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.fromRGB(33, 214, 255)
        Highlight.FillTransparency = 0.75
        Highlight.OutlineColor = Color3.fromRGB(24, 232, 255)
        Highlight.OutlineTransparency = 0
        Highlight.Parent = CasterModel
        Highlight.Name = "mikuhighlightsing"

        local Aura = Effects:Create(MikuAssets.SingingAura)
        Aura.CFrame = CasterModel:GetPivot()
        Effects:Weld(Aura, CasterModel.PrimaryPart)
        EffectsLibrary:Play("Miku_ToggleLeek", Caster, "Enable")

        local MikuSinging = Effects:Create(MikuAssets.SpecialAuraMusic)
        MikuSinging:ScaleTo(0.001)
        MikuSinging:PivotTo(CasterModel:GetPivot() * CFrame.new(0, if IsEx then 2 else 0.4, 0))
        Effects:Weld(MikuSinging.Main, CasterModel.PrimaryPart)
        Effects:TweenModel(MikuSinging, 1, 0.25, 'Quart')

        local Mesh = if IsEx then Effects:Create(MikuAssets.TransparentOrb) else nil

        local Thread = task.spawn(function()
            if not IsEx then
                return
            end

            Mesh.Transparency = 1
            Effects:Tween(Mesh, { 0.3, 'Quad' }, { Transparency = 0.5 })

            local Clock = 0
            while true do
                Clock += (task.wait() * math.tau)

                local Angle = math.sin(Clock)
                local Sz = 7 + Angle

                Mesh.CFrame = CFrame.lookAlong(CasterModel.Torso.Position, Vector3.zAxis)
                Mesh.Size = vector.create(Sz, Sz, Sz)
            end
        end)

        Cache[Caster] = function()
            if Mesh then
                Mesh:Destroy()
            end

            task.cancel(Thread)

            Effects:CleanUp(Aura, 2)
            Effects:Toggle(Aura, false)

            Effects:Toggle(MikuSinging.Main.Aura, false)
            Effects:CleanUp(MikuSinging, 2)
            for _, Beam in MikuSinging:GetDescendants() do
                if Beam:IsA("Beam") then
                    Effects:FadeOutBeams(Beam, { 0.35 })
                end
            end
        end
    elseif State == 'Disable' then
        EffectsLibrary:Play("Miku_ToggleLeek", Caster, "Enable", 1)

        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

        local Highlight = Caster:GetModel():FindFirstChild("mikuhighlightsing")
        if Highlight then
            Effects:Tween(Highlight, { 0.3 }, {FillTransparency = 1, OutlineTransparency = 1})
            Effects:CleanUp(Highlight, 1)
        end
    end
end