---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local RightSide = vector.create(4.675, 2.314, -0.351)
local LeftSide = vector.create(-4.675, 2.314, -0.351)
local EffectOffset = CFrame.new(-0.000183105469, -0.0383501053, 0.37184906, 0, 0, -1, 0.00953629613, 0.999954641, 0, 0.999954641, -0.00953629613, 0)
local Cache = {}
local Threads = {}
local Fishes = {}

---
return function(
    Caster: Types.Caster,
    State: string,
    fn: () -> ()
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
            Projectile = Effects:MoveProjectile(ProjectileModel, vector.create(10, 4), 120, 1, function(Target): boolean
                Projectile:SetSpeed(20);

                if fn then
                    fn(Target)
                end
            end)
        end


        Effects:CleanUp(function()
            Effects:Toggle(ProjectileModel, false)
            Effects:Tween(ProjectileModel:FindFirstChild('Highlight'), { 0.15 }, {FillTransparency = 1, OutlineTransparency = 1})

            for _, BasePart in ProjectileModel:GetChildren() do
                if BasePart:IsA('MeshPart') then
                    Effects:Tween(BasePart, { 0.25 }, {Transparency = 1})
                end
            end
        end, 1)
    elseif State == 'Charge' then

        if Threads[Caster] then
            task.cancel(Threads[Caster])
        end

        if Cache[Caster] then
            Cache[Caster]()
        end

        ---
        if Fishes[Caster] then
            Fishes[Caster].Time = 7;
            Fishes[Caster].Started = os.clock();
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

        Threads[Caster] = Effects:CleanUp(Cache[Caster], 2)

        ---
        if Fishes[Caster] then
            return;
        end

        local Appearance = Caster:GetAppearance()
        local KoiFish = Effects:Create(KuroAssets.Parent.BlackKoi)
        KoiFish:PivotTo(Caster:GetPivot())
        KoiFish.PrimaryPart.Transparency = 1
        local _, FollowedAttachment = Effects:FollowWithAlignments(KoiFish.PrimaryPart, CasterModel.PrimaryPart, 4500)

        Effects:Tween(KoiFish.PrimaryPart, { 0.3, 'Quad' }, {Transparency = 0})

        local Path = "Characters.Chihiro.Abilities.Special.Fish."
        local ComeOut = Animation:Play(KoiFish, Animation:GetAnim(Path..'ComeOut'))
        
        task.delay(2.15, function()
            ComeOut:Stop(.35)

            FollowedAttachment.Position = LeftSide

            Animation:Play(KoiFish, Animation:GetAnim(Path..'Idle'))
        end)


        ---
        Appearance:BindObject(KoiFish.PrimaryPart, function(self: Instance & {SurfaceAppearance: SurfaceAppearance}, State: boolean, ExtraState: number)  
            if State then
                Effects:Tween(self, {0.5, 'Quad'}, { Transparency = 0 })
            else
                Effects:Tween(self, {0.4, 'Quart'}, { Transparency = 1 })
            end
        end)

        Fishes[Caster] = {
            Time = 7,
            Started = os.clock(),
        };

        local SinceItBegan = os.clock()
        Fishes[Caster].Thread = task.spawn(function()
            while os.clock() - Fishes[Caster].Started < Fishes[Caster].Time do
                local HasAnimFinished = (os.clock() - SinceItBegan) > 2.2

                if HasAnimFinished then
                    local CasterLeft = CasterModel:GetPivot() * CFrame.new(-3, 0, 0)
                    local CasterRight = CasterModel:GetPivot() * CFrame.new(3, 0, 0)
                    local IsRightSide = (CasterRight.Position - KoiFish.PrimaryPart.Position).Magnitude < (CasterLeft.Position - KoiFish.PrimaryPart.Position).Magnitude;
                    local GoalPos = LeftSide

                    if IsRightSide then
                        GoalPos = RightSide
                    end

                    FollowedAttachment.Position = GoalPos
                end
                    

                task.wait()
            end

            Effects:Tween(KoiFish.PrimaryPart, { 0.3, 'Quad' }, {Transparency = 1})
            Appearance:UnbindObject(KoiFish.PrimaryPart)
            Effects:CleanUp(KoiFish, 0.5)

            Fishes[Caster] = nil
        end)
    end
end