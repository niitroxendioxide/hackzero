---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local Cache = {}
local RNG = Random.new()
local MAX = vector.create(99999999999, 99999999999, 99999999999)

---
return function(
    Caster: Types.Caster
): ()
    if Cache[Caster] then
        Cache[Caster].Start = os.clock();

        return;
    end

    local Fishes = Assets.Chihiro
    local DefaultKoi = Effects:Create(Fishes.DefaultKoi);
    DefaultKoi.PrimaryPart.Transparency = 1

    Cache[Caster] = {
        Model = DefaultKoi,
        Start = os.clock(),
        Time = 30,
    }

    local Height = RNG:NextNumber(8, 14)
    local Centre = Caster:GetPivot()
    local IdleAnim = Animation:GetAnim("Characters.Chihiro.Abilities.Special.Fish.Idle");
    local IdleTrack = Animation:Play(DefaultKoi, IdleAnim);

    local Att = Instance.new('Attachment', DefaultKoi.PrimaryPart)
    local Gyro = Instance.new("BodyGyro")
    Gyro.MaxTorque = MAX
    Gyro.P = 450000;
    Gyro.D = 3000;
    Gyro.CFrame = Caster:GetPivot()
    Gyro.Parent = DefaultKoi.PrimaryPart;

    local BodyPosition = Instance.new("AlignPosition")
    BodyPosition.Attachment0 = Att;
    BodyPosition.Mode = 0;
    BodyPosition.MaxForce = math.huge;
    BodyPosition.MaxVelocity = 30;
    BodyPosition.Parent = DefaultKoi.PrimaryPart;
    
    
    --- values
    local CurrentPosition = (Caster:GetPivot() * CFrame.new(0, Height, 0)).Position
    local Offset = vector.create(RNG:NextNumber(-25, 25), 0, RNG:NextNumber(-25, 25))
    local Angle = RNG:NextNumber(-math.pi, math.pi);
    local Direction = math.pi * 1/2
    local Speed = RNG:NextNumber(12, 32)
    local WaveDir = 0
    local CurrentDirection = Caster:GetPivot().LookVector

    IdleTrack:AdjustSpeed(Speed / 18)
    DefaultKoi:PivotTo(Caster:GetPivot())
    Effects:Tween(DefaultKoi.PrimaryPart, { 0.5, 'Sine' }, {Transparency = 0})

    ---
    while os.clock() - Cache[Caster].Start < Cache[Caster].Time do
        ---
        local Delta = task.wait();
        Angle += Delta * Direction;
        WaveDir += Delta * math.pi * 0.333
        Centre = Caster:GetModel():GetPivot().Position

        if (CurrentPosition - (Centre + Offset)).Magnitude < 1 then
            local NewOffset = vector.create(RNG:NextNumber(-50, 50), 0, RNG:NextNumber(-50, 50))
            Offset = NewOffset

            Direction *= -1
        end

        local CurWave = math.sin(WaveDir) * 1.5
        local NextWave = math.sin(WaveDir + 1/64) * 1.5
        local Current = math.cos(Angle) * 3
        local Goal = CFrame.lookAt(CurrentPosition, Centre + Offset)
        CurrentDirection = CurrentDirection:Lerp(Goal.LookVector, Delta * 7)

        CurrentPosition += CurrentDirection * Speed * Delta
        Gyro.CFrame = CFrame.lookAt(Gyro.CFrame.Position, (Goal * CFrame.new(0, NextWave, -5)).Position)
        Gyro.CFrame = Gyro.CFrame:Lerp(Goal, Delta * 7)
        BodyPosition.Position = vector.create(CurrentPosition.X, Height + CurWave, CurrentPosition.Z) + Gyro.CFrame.RightVector*Current
    end

    Effects:Tween(DefaultKoi.PrimaryPart, { 0.5, 'Quart' }, {Transparency = 1})

    Cache[Caster] = nil;

end