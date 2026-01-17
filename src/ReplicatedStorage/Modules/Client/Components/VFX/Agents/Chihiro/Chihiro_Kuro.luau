---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local EffectOffset = CFrame.new(-0.000183105469, -0.0383501053, 0.37184906, 0, 0, -1, 0.00953629613, 0.999954641, 0, 0.999954641, -0.00953629613, 0)
local Cache = {}
local Threads = {}
---
return function(
    Caster: Types.Caster,
    State: string
): ()
    local KuroAssets = Assets.Chihiro.Kuro
    local CasterModel = Caster:GetModel()

    ---
    if State == 'Attack' then

        if Cache[Caster] then
            Cache[Caster]()
        end

        local SlashOffset = CFrame.Angles(0, 0, math.rad(106))
        local SlashEffect = Effects:Create(KuroAssets.Slash, 2.5)
        SlashEffect:PivotTo(CasterModel:GetPivot() * SlashOffset)
        Effects:Emit(SlashEffect)

        local Connection = RunService.Heartbeat:Connect(function(Delta: number)
            SlashEffect:PivotTo(Caster:GetPivot() * SlashOffset)
        end)

        Effects:CleanUp(Connection, 1.5)

        ---
        local Highlight = Instance.new('Highlight')
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillTransparency = 0.1
        Highlight.OutlineTransparency = 1
        Highlight.FillColor = Color3.new()
        Highlight.Parent = CasterModel

        Effects:Tween(Highlight, { 0.25 }, {FillTransparency = 1})
        Effects:CleanUp(Highlight, 0.25)

        ---
        local ProjectileModel = Effects:Create(KuroAssets.SlashModel, 2.5)
        ProjectileModel:PivotTo(CasterModel:GetPivot())

        local Projectile do
            Projectile = Effects:MoveProjectile(ProjectileModel, vector.create(10, 4), 120, 1, function(): boolean
                Projectile:SetSpeed(20);


            end)
        end


        task.delay(1, function()
            Effects:Toggle(ProjectileModel, false)
            Effects:Tween(ProjectileModel:FindFirstChild('Highlight'), { 0.15 }, {FillTransparency = 1, OutlineTransparency = 1})

            for _, BasePart in ProjectileModel:GetChildren() do
                if BasePart:IsA('MeshPart') then
                    Effects:Tween(BasePart, { 0.25 }, {Transparency = 1})
                end
            end
        end)

    elseif State == 'Charge' then

        if Threads[Caster] then
            task.cancel(Threads[Caster])
        end

        if Cache[Caster] then
            Cache[Caster]()
        end

        ---
        local KatanaModel = CasterModel:FindFirstChild("Katana")
        if not KatanaModel then
            return;
        end

        local Highlight = Instance.new('Highlight')
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillTransparency = 0.1
        Highlight.OutlineTransparency = 1
        Highlight.FillColor = Color3.new()
        Highlight.Parent = KatanaModel
        
        local KatanaBladeAura = Effects:Create(KuroAssets.KatanaSurfaceAura, 2, KatanaModel.Blade)

        local ChargeUpEffects = Effects:Create(KuroAssets.UserAura, 2)
        ChargeUpEffects:PivotTo(CasterModel:GetPivot())

        local KatanaParticleAura = Effects:Create(KuroAssets.KatanaAura, 2)
        KatanaParticleAura:PivotTo(KatanaModel.Blade.CFrame * EffectOffset)
        Effects:Weld(KatanaParticleAura, KatanaModel.Blade)

        Cache[Caster] = function()
            KatanaBladeAura.Enabled = false;
            Effects:Toggle(ChargeUpEffects, false)
            Effects:Toggle(KatanaParticleAura, false)
            
            Highlight:Destroy()
        end

        Threads[Caster] = task.delay(2, Cache[Caster])
    end
end