---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets
local GokuAssets = Assets.Effects.Agents.Goku
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local EffectUtil = require(Shared.Utility.Effects)
local Audio = require(Client.Libraries.Audio)

local Cache = {}

local function ShiftHue(Color: Color3, HueShift: number): Color3
	local H, S, V = Color:ToHSV()
	local NewHue = (H + HueShift) % 1
	return Color3.fromHSV(NewHue, S, V)
end

function Shoot(Caster: Types.ClientAgent, Offset: CFrame?, Config: {}?, HueShift: number?)
    Config = Config or {}
    local KameLength = Config.Time or 1.35;
    local SizeSpeed = Config.Speed or 1;
    local Length = Config.Length or 100; 

    Audio:PlayFromDb('Effects/Goku/Kame_Blast', Caster:GetPivot().Position)

    local Highlight = Instance.new("Highlight")
    Highlight.FillColor = Color3.new()
    Highlight.OutlineTransparency = 1
    Highlight.FillTransparency = 0.75
    Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    Highlight.Parent = Caster:GetModel()

    --
    local BaseCF = CFrame.lookAlong(Caster:GetModel():GetPivot().Position, Caster:GetPivot().LookVector)
    local At = BaseCF * (Offset or CFrame.new(0, 0.078, -4.41))
    local Beam = EffectUtil:Create(GokuAssets.Kamehameha.Beam, 2.5)
    local Aura = EffectUtil:Create(GokuAssets.Kamehameha.Aura, 2.5)

    if typeof(HueShift) == 'number' and (math.abs(HueShift :: number) > 0) then
        HueShift = (HueShift / 360);

        for _, Descendant in Beam:GetDescendants() do
            if Descendant:IsA('BasePart') then
                Descendant.Color = ShiftHue(Descendant.Color, HueShift)
            elseif Descendant:IsA('Beam') or Descendant:IsA("ParticleEmitter") then
                local NewValue = ShiftHue(Descendant.Color.Keypoints[1].Value, HueShift)
                    
                Descendant.Color = ColorSequence.new(NewValue)
            end
        end

        for _, Descendant in Aura:GetDescendants() do
            if Descendant:IsA('Beam') or Descendant:IsA("ParticleEmitter") then
                local NewValue = ShiftHue(Descendant.Color.Keypoints[1].Value, HueShift)
                    
                Descendant.Color = ColorSequence.new(NewValue)
            end
        end
    end

    Aura:PivotTo(Caster:GetModel():GetPivot())
    Beam:PivotTo(At)

    for _, Ball in Beam.Ball:GetChildren() do
        if not Ball:IsA('BasePart') then
            continue
        end

        local ballSize = Ball.Size
        Ball.Size = vector.zero

        EffectUtil:Tween(Ball, {.2, 'Back'}, {
            Size = ballSize,
        })
    end

    local BaseBallPivot = Beam.Ball:GetPivot()
    Beam.End:PivotTo(BaseBallPivot)

    task.spawn(function()
        local GoalCFrame = BaseBallPivot * CFrame.new(0, 0, -Length)
        local TimeActive = os.clock();
        while (os.clock() - TimeActive) < SizeSpeed do
            local Alpha = TweenService:GetValue(((os.clock() - TimeActive) / SizeSpeed), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            Beam.End:PivotTo(BaseBallPivot:Lerp(GoalCFrame, Alpha) * CFrame.Angles(0, math.pi, 0))

            task.wait()
        end
    end)

    for _, Ball in Beam.End:GetChildren() do
        if not Ball:IsA('BasePart') then
            continue
        end

        local ballSize = Ball.Size
        Ball.Size = vector.zero

        EffectUtil:Tween(Ball, {.2, 'Back'}, {
            Size = ballSize,
        })
    end
    

    for _, Cylinder in Beam.Beam:GetChildren() do
        local CylSize = Cylinder.Size

        Cylinder.CFrame *= CFrame.new(-Cylinder.Size.X/2, 0, 0)
        Cylinder.Size *= vector.create(0, 1, 1);

        EffectUtil:Tween(Cylinder, {SizeSpeed, 'Quad'}, {
            CFrame = At * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(Length/2, 0, 0),
            Size = vector.create(Length, CylSize.Y, CylSize.Z),
        })
    end

    for _, Attachment in Beam.BeamFX:GetChildren() do
        if not (string.match(Attachment.Name, "End")) then 
            continue 
        end
        
        local Position = Attachment.Position
        
        Attachment.Position = Position * vector.create(1, 1, 0)
        
        EffectUtil:Tween(Attachment, {SizeSpeed, 'Quad'}, {
            Position = vector.create(Position.X, Position.Y, -Length / 2)
        })
    end

    local Cast = EffectUtil:CastMapRaycast(At, vector.create(0, -4.5))
    if Cast then
        Beam.GroundFX.Size *= vector.create(1, 1, 0)
        Beam.GroundFX.CFrame = CFrame.lookAlong(Cast.Position, At.LookVector)

        EffectUtil:Tween(Beam.GroundFX, {SizeSpeed, 'Quint'}, {
            Size = vector.create(Beam.GroundFX.Size.X, Beam.GroundFX.Size.Y, Length),
            CFrame = CFrame.lookAlong(Cast.Position, At.LookVector) * CFrame.new(0, 0, -Length/2)
        })
    else
        EffectUtil:Toggle(Beam.GroundFX, false)
    end

    --
    task.delay(KameLength, function()

        EffectUtil:Toggle(Aura, false)
        EffectUtil:Tween(Aura.Attachment.PointLight, {.25}, {Brightness = 0})

        EffectUtil:Tween(Highlight, {.4}, {FillTransparency = 1})

        EffectUtil:CleanUp(Highlight, .4)

        for _, Cylinder in Beam.Beam:GetChildren() do
            local CylSize = Cylinder.Size

            EffectUtil:Tween(Cylinder, {.3, 'Sine'}, {
                Size = vector.create(CylSize.X, 0, 0),
            })
        end

        for _, Ball in Beam.Ball:GetChildren() do
            if not Ball:IsA('BasePart') then
                continue
            end

            EffectUtil:Tween(Ball, {.3, 'Sine'}, {
                Size = vector.zero,
            })
        end

        for _, Ball in Beam.End:GetChildren() do
            if not Ball:IsA('BasePart') then
                continue
            end

            EffectUtil:Tween(Ball, {.3, 'Sine'}, {
                Size = vector.zero,
            })
        end

        for _, Beam in Beam.Ball.Beams:GetChildren() do
            EffectUtil:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end

        for _, Beam in Beam.End.Beams:GetChildren() do
            EffectUtil:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end

        for _, Attachment in Beam.Ball.Out:GetChildren() do
            if not Attachment:IsA("Attachment") then continue end
            local Position = Attachment.Position
            
            EffectUtil:Tween(Attachment, {.35, 'Sine'}, {
                Position = vector.create(0, 0, Position.Z)
            })
        end

        for _, Attachment in Beam.BeamFX:GetChildren() do
            if not Attachment:IsA("Attachment") then continue end
            local Position = Attachment.Position
            
            EffectUtil:Tween(Attachment, {.35, 'Sine'}, {
                Position = vector.create(0, 0, Position.Z)
            })
        end

        EffectUtil:Toggle(Beam, false)

        for _, Beam in Beam.BeamFX.Beams:GetChildren() do
            EffectUtil:Tween(Beam, {.4, 'Sine'}, {Width0 = 0, Width1 = 0})
        end
    
    end)
end

local function GetBallCF(Caster: Types.Caster)
    local Model = Caster:GetModel()
    local LArm = Model:FindFirstChild("Left Arm")
    local RArm = Model:FindFirstChild("Right Arm")

    local LCF, RCF = LArm.CFrame * CFrame.new(0, -1, 0), RArm.CFrame * CFrame.new(0, -1, 0)
    local Centre = LCF:Lerp(RCF, 0.5) * CFrame.new(0, .3, 0)

    return Centre
end

---
return function(Caster: Types.Caster, State: boolean, Offset: CFrame?, Config: {}, HueShift: number?): ()
    --

    if State then
        if Cache[Caster] then
            Audio:FadeOutAudio(Cache[Caster], .25)
            Cache[Caster] = nil
        end

        Shoot(Caster, Offset, Config, HueShift)
    else
        Cache[Caster] = Audio:PlayFromDb('Effects/Goku/Kame_Startup', Caster:GetPivot().Position)

        local ChargeBall = EffectUtil:Create(GokuAssets.Kamehameha.KameBall, 3)
        ChargeBall:PivotTo(GetBallCF(Caster))

        ChargeBall.Size *= 0;
        EffectUtil:Tween(ChargeBall, {.1, 'Quad'}, {Size = vector.one * 1.085})

        local Aura = EffectUtil:Create(GokuAssets.Kamehameha.ChargeAura, 2.5)

        Aura:PivotTo(Caster:GetPivot())

        local Active_Time = 0;
        while Active_Time < 0.9 do
            Active_Time += EffectUtil:Wait()

            ChargeBall:PivotTo(GetBallCF(Caster))
        end

        ChargeBall.Transparency = 1
        EffectUtil:Toggle(ChargeBall, false)
        EffectUtil:Toggle(Aura, false)
    end
end 