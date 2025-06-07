local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets.Destructibles
local Client = ReplicatedStorage.Modules.Client
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ClientDestructible = require(Client.Classes.ClientDestructible)

local CrystalObjClass = ClientDestructible.new("Crystals")
local Rng = Random.new()

CrystalObjClass:OnCreate(function(Object)
    local CrystalBase = Assets:FindFirstChild('Crystal')
    if not CrystalBase then
        return
    end

    local CFPos = CFrame.new(Object.Position)
    local Model = Instance.new("Model")
    Model.Parent = ClientDestructible.Parent

    local Max = Rng:NextInteger(4, 6)
    for i = 1, Max do
        local AngleMult = i == 1 and 0.15 or 1
        local ScaleMult = i == 1 and 1 or 1 - ((i / Max) * 0.225) * Rng:NextInteger(0.9, 1.1)
        local Angle = math.rad(Rng:NextInteger(0, 360))
        local RX = Rng:NextNumber(math.pi * 0.03, math.pi * 0.05) * AngleMult
        local RZ = Rng:NextNumber(math.pi * 0.15, math.pi * 0.4) * AngleMult
        local PosOffset = Rng:NextUnitVector() * 0.75
        local CFOffset = CFrame.new(PosOffset.X, -math.abs(PosOffset.Y), PosOffset.Z)

        print(ScaleMult)

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

    for _, Obj in Model:GetChildren() do
        if not Obj:IsA("Model") then continue end
        local Value = Instance.new('NumberValue')
        local MaxScale = Obj:GetScale()
        Value.Value = 0.01

        Value.Changed:Connect(function(k)
            Obj:ScaleTo(k)
        end)

        Effects:Tween(Value, {.25 + Rng:NextNumber(0.1, 0.3), 'Back', 'Out'}, {Value = MaxScale})
    end
end)

CrystalObjClass:OnDestroy(function(Object)
    print(Object, ' to destroy')
end)

return CrystalObjClass
