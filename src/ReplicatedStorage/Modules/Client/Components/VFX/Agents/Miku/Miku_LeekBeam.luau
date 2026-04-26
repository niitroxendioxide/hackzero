---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
function ShootBeam(Character: Model)
    local BaseCF = Character:GetPivot() * CFrame.new(-0.007, 0.674, -5.671)
    local MikuAssets = Assets.Miku

    
    --
    local Beam = Effects:Create(MikuAssets.M1Beam, 2.5)
    local SizeTime = 0.2;
    local Length = 35 

    Beam:PivotTo(BaseCF)

    for _, Ball in Beam.Ball:GetChildren() do
        if not Ball:IsA('BasePart') then
            continue
        end

        local ballSize = Ball.Size
        Ball.Size = vector.zero

        Effects:Tween(Ball, {.2, 'Back'}, {
            Size = ballSize,
        })
    end
    

    for _, Cylinder in Beam.Beam:GetChildren() do
        local CylSize = Cylinder.Size

        Cylinder.CFrame *= CFrame.new(0, 0, Cylinder.Size.Z/2)
        Cylinder.Size *= vector.create(1, 1, 0);

        Effects:Tween(Cylinder, {SizeTime, 'Quad'}, {
            CFrame = BaseCF * CFrame.new(0, 0, -Length/2),
            Size = vector.create(CylSize.X, CylSize.Y, Length),
        })
    end

    for _, Attachment in Beam.BeamFX:GetChildren() do
        if not (string.match(Attachment.Name, "End")) then continue end
        
        local Position = Attachment.Position
        
        Attachment.Position = Position * vector.create(1, 1, 0)
        
        Effects:Tween(Attachment, {SizeTime, 'Quad'}, {
            Position = vector.create(Position.X, Position.Y, -Length)
        })
    end

    --
    task.delay(SizeTime * 0.95, function()

        for _, Cylinder in Beam.Beam:GetChildren() do
            local CylSize = Cylinder.Size

            Effects:Tween(Cylinder, {.3, 'Sine'}, {
                Size = vector.create(0, 0, CylSize.Z),
            })

            task.delay(0.3, function()
                Cylinder.Transparency = 1
            end)
        end

        for _, Ball in Beam.Ball:GetChildren() do
            if not Ball:IsA('BasePart') then
                continue
            end

            Effects:Tween(Ball, {.3, 'Sine'}, {
                Size = vector.zero,
            })
        end

        for _, Beam in Beam.Ball.Beams:GetChildren() do
            Effects:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end

        for _, Attachment in Beam.Ball.Out:GetChildren() do
            if not Attachment:IsA("Attachment") then continue end
            local Position = Attachment.Position
            
            Effects:Tween(Attachment, {.35, 'Sine'}, {
                Position = vector.create(0, 0, Position.Z)
            })
        end

        for _, Attachment in Beam.BeamFX:GetChildren() do
            if not Attachment:IsA("Attachment") then continue end
            local Position = Attachment.Position
            
            Effects:Tween(Attachment, {.35, 'Sine'}, {
                Position = vector.create(0, 0, Position.Z)
            })
        end

        Effects:Toggle(Beam, false)

        for _, Beam in Beam.BeamFX.Beams:GetChildren() do
            Effects:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end
    
    end)
end


---
local Cache = {}
return function(
    Caster: Types.Caster,
    State: boolean
): ()
    local MikuAssets = Assets.Miku
    local Model = Caster:GetModel()
    local LeekModel = Model:FindFirstChild("Leek")


    ---
    if State == true then
        if Cache[Caster] then
            Effects:Toggle(Cache[Caster], false)
            Effects:CleanUp(Cache[Caster], 1)

            Cache[Caster] = nil
        end

        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.fromRGB(33, 214, 255)
        Highlight.FillTransparency = 0.95
        Highlight.OutlineColor = Color3.fromRGB(24, 232, 255)
        Highlight.OutlineTransparency = .5
        Highlight.Parent = LeekModel

        Effects:Tween(Highlight, { 0.25 }, { FillTransparency = 1, OutlineTransparency = 1 })
        Effects:CleanUp(Highlight, 0.5)

        local MikuLeekBeamCharge = MikuAssets.MikuBeamCharge:Clone()
        MikuLeekBeamCharge.Parent = LeekModel.PrimaryPart

        Cache[Caster] = MikuLeekBeamCharge;
    elseif State == false then
        if Cache[Caster] then
            Effects:Toggle(Cache[Caster], false)
            Effects:CleanUp(Cache[Caster], 1)

            Cache[Caster] = nil
        end

        ---
        ShootBeam(Caster:GetModel())
    end
end