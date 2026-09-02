---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local LightningBolt = require(Client.Utility.Libraries.LightningBolt)
local ForgeVFX = require(ReplicatedStorage.Packages.ForgeVFX)

local Offset = CFrame.new(-0.013, -0.793, 0.033)
local Cache = {}

--[[local function CreateBolt(CasterModel: Model, Ground: RaycastResult<BasePart> & {Color: Color3})
    local KakashiVFX = Assets.Effects.Agents.Kakashi
    local Color = Color3.fromRGB(112, 150, 255)
    local Parent = Effects:GetParent(script.Name)
    
    local A1 = Instance.new('Attachment')
    A1.Name = 'LightningBoltAttachment'
    A1.Position = vector.create(Effects:Random(-0.5, 0.5), Effects:Random(-1, 1), Effects:Random(-0.5, 0.5))
    A1.WorldAxis = Effects:RandomV3()
    A1.Parent = CasterModel.PrimaryPart
    
    local Attachment = Instance.new('Attachment')
    Attachment.WorldPosition = A1.WorldPosition
    Attachment.WorldAxis = Effects:RandomV3()
    Attachment.Parent = workspace.Terrain
    Effects:Tween(Attachment, {.1}, {WorldPosition = Ground.Position})

    local Floor = Effects:Create(KakashiVFX.FloorPart, 1.25)
    Floor:PivotTo(CFrame.lookAlong(Ground.Position, Ground.Normal) * CFrame.Angles(-math.pi/2, 0, 0))
    Floor.Parent = Parent
    Effects:RecolorSmoke(Ground, Floor:GetDescendants())

    task.delay(.1, function()
        Effects:Emit(Floor, true)
    end)

    Effects:CleanUp(Floor, 2.5)
    
    local CurveSize = 5.5
    local Radius = {0.9, 2.25}
    local RandomCurve = Effects:Random(-CurveSize, CurveSize)

    local NewBolt = LightningBolt.new(A1, Attachment, Effects:Random(8, 14))
    NewBolt.CurveSize0, NewBolt.CurveSize1 = RandomCurve, -RandomCurve
    NewBolt.PulseSpeed = Effects:Random(9, 24)
    NewBolt.PulseLength = Effects:Random(.75, 4)
    NewBolt.ContractFrom = 0
    NewBolt.MinRadius, NewBolt.MaxRadius = Radius[1], Radius[2]
    NewBolt.Thickness = Effects:Random(.15, .3)
    NewBolt.Frequency = Effects:Random(.2, .5)
    NewBolt.Color = Color
    NewBolt.Parent = Parent
    
    Effects:CleanUp(Attachment, 5)
    Effects:CleanUp(A1, 5)
end]]

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local Args = {...}

    local UseBothArms = Args[1]
    local KakashiVfx = Assets.Effects.Agents.Kakashi
    local Model = typeof(Caster) == 'Instance' and Caster:IsA("Model") and Caster or Caster:GetModel()
    local RightArm = Model:FindFirstChild("Right Arm");
    local LeftArm = Model:FindFirstChild("Left Arm");
    
    if State == 'Charge' then
        ---
        local CastEffect = Effects:Create(KakashiVfx.TriggerEffect, 2);
        CastEffect:PivotTo(Caster:GetModel():GetPivot());
        Effects:Emit(CastEffect, true)

        local NewShockwave = Effects:Create(Effects.General.Shockwaves.SmallGroundWind, 2.25)
        NewShockwave:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, -2.5, -0.7))
        ForgeVFX.emit(NewShockwave)

        local EffectsList = {}
        local ArmsToUse = {RightArm, if UseBothArms then LeftArm else nil};
        for _, Arm in ArmsToUse do
            local At = CFrame.lookAlong((Arm.CFrame * Offset).Position, Caster:GetPivot().LookVector)
            local RaikiriVFX = Effects:Create(KakashiVfx.Raikiri, nil, false);
            RaikiriVFX:PivotTo(At);
            RaikiriVFX.Parent = workspace

            if UseBothArms then
                RaikiriVFX:ScaleTo(0.92)
            end

            Effects:Weld(RaikiriVFX.PrimaryPart, Arm)

            for _, Particle: ParticleEmitter in RaikiriVFX:GetDescendants() do
                if Particle:IsA('ParticleEmitter') then
                    local TimeScale = Particle.TimeScale;

                    Particle.TimeScale = 0; 
                    Effects:Tween(Particle, { .15 }, {TimeScale = TimeScale})
                end
            end

            table.insert(EffectsList, RaikiriVFX)
        end
        
        Cache[Caster] = {VFX = EffectsList, Thread = nil, Active = true}
        Cache[Caster].Thread = task.spawn(function()
            local Disabled = Settings:Get('DisableLightningEffects', 'Graphics');
            if Disabled then
                return;
            end

            local TimePer = UseBothArms and 1 / 9 or 1/18
            local Divisor = UseBothArms and 0.5 or 1
            local Clock = os.clock()

            while true do
                if Cache[Caster].Active == false then
                    task.wait()
                    continue
                end

                if (os.clock() - Clock) > (TimePer)  then
                    Clock = os.clock()

                    for _, Arm in ArmsToUse do
                        local Offset = vector.create(Effects:Random(-7, 7) * Divisor, 0, Effects:Random(-7, 7) * Divisor)
                        local BasePos = Arm.Position;

                        local Cast = Effects:CastMapRaycast(BasePos + Offset, vector.create(0, -7))
                        if Cast then
                            Effects:CreateLightningBolt({
                                CasterModel = Caster:GetModel(),
                                Ground = Cast,
                                Color3 = Color3.fromRGB(112, 150, 255),
                                SubpartColor = Color3.fromRGB(51, 78, 255),
                                BoltCount = 27
                            })
                            --CreateBolt(Caster:GetModel(), Cast)
                        end
                    end
    
                end

                task.wait()
            end
        end)
    elseif State == 'Delete' then
        local Data = Cache[Caster]
        if not Data then
            return
        end

        local Raikiri = Data.VFX
        local Thread = Data.Thread

        if Raikiri then
            for _, obj in Raikiri do
                Effects:Toggle(obj, false)
                Effects:CleanUp(obj, .5)
            end
        end

        if typeof(Thread) == 'thread' and Thread ~= coroutine.running() then
            task.cancel(Thread)
        end
    elseif State == 'PauseAndDelete' then
        local WhichToDelete = Args[1]
        local Data = Cache[Caster]
        if not Data then
            return
        end

        local Raikiris = Data.VFX
        Data.Active = false;
        if Raikiris[WhichToDelete] then
            Effects:Toggle(Raikiris[WhichToDelete], false)
            Effects:CleanUp(Raikiris[WhichToDelete], 0.5)
        end
    elseif State == 'Resume' then
        local Data = Cache[Caster]
        if not Data then
            return
        end

        Data.Active = true;
    end
end