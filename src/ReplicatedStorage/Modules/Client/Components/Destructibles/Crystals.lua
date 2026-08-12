local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.Destructibles
local Client = ReplicatedStorage.Modules.Client
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ClientDestructible = require(Client.Classes.ClientDestructible)

local CrystalObjClass = ClientDestructible.new("Crystals")

local ColorOptions = {
    Color3.fromRGB(67, 15, 126),
    Color3.fromRGB(126, 76, 14),
    Color3.fromRGB(0, 61, 118),
    Color3.fromRGB(31, 31, 31),
}

local LastUsed = Color3.new()

CrystalObjClass:OnCreate(function(Object)
    local CrystalBase = Assets:FindFirstChild('Crystal_New')
    if not CrystalBase then
        return
    end

    local BaseCF = Object.CFrame

    local Possible = table.clone(ColorOptions)
    local Found = table.find(Possible, LastUsed)
    if Found then
        table.remove(Possible, Found)
    end

    local Color = Possible[math.random(1, #Possible)]
    LastUsed = Color;

    local H, S, V = Color:ToHSV()
    local GlowColor = Color3.fromHSV(H, math.lerp(S, 1, 0.85), math.lerp(V, 1, 0.85))

    local NewModel = CrystalBase:Clone()
    NewModel:ScaleTo(0.001)
    NewModel:PivotTo(BaseCF)
    NewModel.Parent = workspace.World.Effects

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.OutlineTransparency = 0
    Highlight.FillTransparency = 0
    Highlight.OutlineColor = GlowColor
    Highlight.FillColor = GlowColor
    Highlight.Parent = NewModel

    Effects:TweenModel(NewModel, 1, 0.45, 'Back')
    Effects:Tween(Highlight, {.3}, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, .5)

    for _, part in NewModel:GetDescendants() do
        if part:IsA('SurfaceAppearance') then
            part.EmissiveTint = Color
        end
    end

    Object.Cache.Color = Color;
    Object.Cache.Model = NewModel

    --[[local Max = Rng:NextInteger(4, 6)
    for i = 1, Max do
        local AngleMult = i == 1 and 0.15 or 1
        local ScaleMult = i == 1 and 1 or 1 - ((i / Max) * 0.225) * Rng:NextInteger(0.9, 1.1)
        local Angle = math.rad(Rng:NextInteger(0, 360))
        local RX = Rng:NextNumber(math.pi * 0.03, math.pi * 0.05) * AngleMult
        local RZ = Rng:NextNumber(math.pi * 0.15, math.pi * 0.4) * AngleMult
        local PosOffset = Rng:NextUnitVector() * 0.75
        local CFOffset = CFrame.new(PosOffset.X, -math.abs(PosOffset.Y), PosOffset.Z)

        local Crystal = CrystalBase:Clone()
        Crystal:ScaleTo(ScaleMult)
        Crystal:PivotTo(CFPos * CFOffset * CFrame.Angles(0, Angle, 0) * CFrame.Angles(RX, 0, RZ))
        Crystal.Parent = Model
    end

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.OutlineTransparency = 0
    Highlight.FillTransparency = 0
    Highlight.OutlineColor = Color3.fromRGB(153, 85, 255)
    Highlight.FillColor = Color3.fromRGB(153, 85, 255)
    Highlight.Parent = Model

    Effects:Tween(Highlight, {.3}, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, .5)

    local Root = Instance.new('Part')
    Root.Anchored = true
    Root.CanCollide = false
    Root.CFrame = CFPos
    Root.Parent = Model
    Model.PrimaryPart = Root;

    for _, Obj in Model:GetChildren() do
        if not Obj:IsA("Model") then continue end
        local Value = Instance.new('NumberValue')
        local MaxScale = Obj:GetScale()
        Value.Value = 0.01

        Value.Changed:Connect(function(k)
            Obj:ScaleTo(k)
        end)

        Effects:Tween(Value, {.25 + Rng:NextNumber(0.1, 0.3), 'Back', 'Out'}, {Value = MaxScale})
    end]]
end)

CrystalObjClass:OnDestroy(function(Object)
    local Model: Model = Object.Cache.Model;
    if not Model then return end

    Object.Collider.CanCollide = false
    Object.Collider.CanQuery = false
    Model.Parent = workspace.World.Effects

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.OutlineTransparency = 0
    Highlight.FillTransparency = 0
    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    Highlight.FillColor = Color3.fromRGB(255, 255, 255)
    Highlight.Parent = Object.Cache.Model

    Effects:Tween(Highlight, {.2}, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, .2)

    local ParticleColor = ColorSequence.new(Object.Cache.Color);
    for _, part in Model:GetDescendants() do
        if part:IsA('MeshPart') then
            local TransDelay = 0;
            part.CollisionGroup = 'Effects'
            if part.Name ~= 'Base' then
                TransDelay = 0.2;
                part.Anchored = false;

                part:ApplyImpulseAtPosition(Effects:RandomV3() * Effects:Random(45, 75), Effects:RandomV3() * Effects:Random(0.6, 5))
                Effects:Tween(part, { .75, 'Quad' }, { Size = vector.zero })
            end

            task.delay(TransDelay, function()
                Effects:Tween(part, { .75 - TransDelay, 'Sine' }, { Transparency = 1 })
            end)
        elseif part:IsA('ParticleEmitter') then
            if part:HasTag('Recolorable') then
                part.Color = ParticleColor;
            end
            part:Emit(part:GetAttribute('EmitCount'))
        end
    end

    Effects:CleanUp(Model, 2)
end)

CrystalObjClass:OnHit(function(Object)
    local Model = Object.Cache.Model :: Model?
    if not Model then return end

    local Highlight = Instance.new("Highlight")
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.OutlineTransparency = 0
    Highlight.FillTransparency = 0
    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    Highlight.FillColor = Color3.fromRGB(255, 255, 255)
    Highlight.Parent = Object.Cache.Model

    Effects:Tween(Highlight, {.2}, {FillTransparency = 1, OutlineTransparency = 1})
    Effects:CleanUp(Highlight, .2)
end)

return CrystalObjClass
