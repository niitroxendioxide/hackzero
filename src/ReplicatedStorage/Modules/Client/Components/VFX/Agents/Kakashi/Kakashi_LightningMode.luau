---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)


local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    const _Args = {...}

    const KakashiVfx = Assets.Effects.Agents.Kakashi
    const BaseModel = Caster:GetModel()

    if State == 'Enter' then
        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded;
        Highlight.OutlineColor = Color3.fromRGB(92, 163, 254)
        Highlight.FillTransparency = 1;
        Highlight.OutlineTransparency = 0.15;
        Highlight.Parent = BaseModel

        local CastEffect = Effects:Create(KakashiVfx.TriggerEffect, 2);
        CastEffect:PivotTo(Caster:GetModel():GetPivot());
        Effects:Emit(CastEffect, true)

        const AuraVFX = {}
        for _, Part in BaseModel:GetChildren() do
            if Part:IsA('BasePart') and Part.Name ~= 'HumanoidRootPart' then
                for _, v in KakashiVfx.ElAura:GetChildren() do
                    const Kfx = Effects:Create(v, nil, Part)
                    Kfx.Parent = Part;
                    Kfx.Enabled = true;
                    Kfx.LockedToPart = true;
                    table.insert(AuraVFX, Kfx)
                end
            end
        end

        local Thread = task.spawn(function()
            while Caster:HasTag('LightningMode') do
                task.wait()
            end

            Cache[Caster]()
        end)

        Cache[Caster] = function()
            Effects:CleanUp(Thread)
            Highlight:Destroy()    

            for _, VFX in AuraVFX do
                Effects:Toggle(VFX, false)
                Effects:CleanUp(VFX, 2.25)
            end
        end
    elseif State == 'Vanish' then
        Effects:CleanUp(Cache[Caster])
    end
end