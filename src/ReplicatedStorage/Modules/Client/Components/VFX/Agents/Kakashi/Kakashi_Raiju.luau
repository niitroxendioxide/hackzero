---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local LibFX = require(Client.Libraries.Effects)
local Settings = require(Client.Packages.Settings)
local LightningBolt = require(Client.Utility.Libraries.LightningBolt)

local Offset = CFrame.new(0, -1, 0)
local Cache = {}
local ChargeVFX = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local Args = {...}

    local KakashiVfx = Assets.Effects.Agents.Kakashi
    local Model = typeof(Caster) == 'Instance' and Caster:IsA("Model") and Caster or Caster:GetModel()
    local RightArm = Model:FindFirstChild("Right Arm");
    const Id = Args[1]
    const Time = Args[2] or 1.5

    if not Cache[Caster] then
        Cache[Caster] = {}
    end

    if State == 'Prepare' then
        if ChargeVFX[Caster] then
            return
        end

        local RaikiriVFX = Effects:Create(KakashiVfx.Raikiri, nil);
        RaikiriVFX:PivotTo(RightArm.CFrame * Offset);
        Effects:Weld(RightArm, RaikiriVFX.PrimaryPart);

        ChargeVFX[Caster] = function()
            ChargeVFX[Caster] = nil
            Effects:Toggle(RaikiriVFX, false)
            Effects:CleanUp(RaikiriVFX, 10)
        end;
    elseif State == 'Summon' then
        local Direction = Args[4] or vector.create(0, 0, -1)
        const Relative = Caster:GetPivot():VectorToWorldSpace(Direction)
        const InuVFX = Effects:Create(KakashiVfx.Inu, 10)
        const EndAtt = InuVFX.Fire.End
        EndAtt.Parent = RightArm
        EndAtt.Position = vector.create(0, -0.9, 0)

        InuVFX:PivotTo(CFrame.lookAlong(Caster:GetPivot().Position, Relative))
        
        const Speed = Args[3]
        local Angle = 0;
        local AngleY = 0;
        const MoveClass = Effects:MoveProjectile(InuVFX, vector.create(4, 4, 4), Speed, 1.75, function(Target, ...): boolean
            return true
        end, nil, function(Delta: number, ...)
            Angle += Delta * math.tau * 4;
            AngleY += Delta * math.tau * 3;
            InuVFX.Dog.Rig.C0 = CFrame.new(math.cos(Angle) * 0.33, math.max(math.sin(AngleY) * 1.25, 0), 0)
        end)

        local Thread = task.delay(Time, function()
            Cache[Caster][Id]()
        end)

        Cache[Caster][Id] = function()
            if Thread ~= coroutine.running() then
                task.cancel(Thread)
            end

            Effects:Tween(InuVFX.Highlight, {0.1, 'Quad'}, {FillTransparency = 1, OutlineTransparency = 1})

            for _, v in InuVFX:GetChildren() do
                if v:IsA('BasePart') then
                    Effects:Tween(v, {0.15, 'Quad'}, {Transparency = 1})
                end
            end

            Cache[Caster][Id] = nil;

            local Count = Table:GetDictLength(Cache[Caster])

            if Count <= 1 and typeof(ChargeVFX[Caster]) == "function" then
                ChargeVFX[Caster]()
            end

            for _, v in InuVFX:GetDescendants() do
                if v:IsA('Beam') then
                    Effects:Tween(v, {Effects:Random(0.125, 0.225), 'Back', 'In'}, {Width0 = 0, Width1 = 0})
                end
            end

            Effects:Toggle(InuVFX.Dog, false)
            Effects:Toggle(InuVFX.AuraBlock, false)
            Effects:Toggle(InuVFX.Fire.Smoke, false)

            const Clock = os.clock();
            while os.clock() - Clock < 0.2 do
                const Alpha = 1 - TweenService:GetValue((os.clock() - Clock) / 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                MoveClass:SetSpeed(Alpha * Speed)

                task.wait()
            end
            
        end

    elseif State == 'Delete' then
        if Cache[Caster][Id] then
            Cache[Caster][Id]()
        end
    elseif State == 'DeleteEXP' then
        local EnemyObject = Enemies:GetEnemy(Args[2])

        EnemyObject:Hit()
        LibFX:Play("Hit", EnemyObject, {
            Highlight = true, 
            HighlightColor = Color3.fromRGB(0, 180, 180),
            HueShift = 170,
        })

        LibFX:Play("Kakashi_Crash", EnemyObject:GetPivot())

        if Cache[Caster][Id] then
            Cache[Caster][Id]()
        end
    end
end