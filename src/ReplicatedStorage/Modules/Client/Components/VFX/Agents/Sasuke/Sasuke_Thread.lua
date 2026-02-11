---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
local Library = require(Client.Libraries.Effects)

---
local Cache = {}

---
return function(Caster: Types.AgentClass, EnemyId: number, Type: number, fn): ()
    if not Cache[Caster] then
        Cache[Caster] = {}
    end

    local VFXAssets = Assets.Effects.Agents.Sasuke.KatonThread
    local SasukeVFX = Assets.Effects.Agents.Sasuke
    local EnemyObject = Enemies:GetEnemy(EnemyId)
    local CasterModel = Caster:GetModel()
    local Appearance = Caster:GetAppearance()

    -- Connect
    if Type == 1 then
        if Cache[Caster][EnemyId] then
            return
        end

        local WeldBase = CasterModel.Head
        local Trail = Effects:Create(VFXAssets.TrailPart)
        Trail:PivotTo(WeldBase.CFrame)

        Effects:Weld(Trail, WeldBase).Name = "threadWeld"

        local End = Trail.End
        Trail.Start.Position = vector.create(0, -0.25)
        End.Parent = EnemyObject:GetModel().PrimaryPart
        End.WorldPosition = Trail.Start.WorldPosition;

        Trail.Connection.CurveSize0 = Effects:Random(-5, 5)
        Trail.Connection.CurveSize1 = Effects:Random(-5, 5)

        Effects:Tween(End, { .25, 'Sine' }, {Position = vector.zero})
        Effects:Tween(Trail.Connection, { .5, 'Elastic' }, {CurveSize0 = 0, CurveSize1 = 0})

        Cache[Caster][EnemyId] = Trail

        Appearance:BindObject(Trail, function(self: Instance, State: boolean)  
            if State then
                for _, Obj: Beam in Trail:GetChildren() do
                    if Obj:IsA("Beam") then
                        Obj.Enabled = true
                    end
                end
            else
                for _, Obj: Beam in Trail:GetChildren() do
                    if Obj:IsA("Beam") then
                        Obj.Enabled = false
                    end
                end
            end
        end)
    -- Disconnect
    elseif Type == 2 then
        local Object = Cache[Caster][EnemyId]
        Cache[Caster][EnemyId] = nil

        local EndAttachment = Object.Connection.Attachment1;
        local WorldCF = EndAttachment.WorldCFrame;
        EndAttachment.Parent = workspace
        EndAttachment.WorldCFrame = WorldCF;

        Effects:CleanUp(Object, 1)
        Effects:Tween(Object.Connection, {0.25, 'Back'}, {Width0 = 0, Width1 = 0})

    -- Lit up
    elseif Type == 3 then
        local Object = Cache[Caster][EnemyId]

        Cache[Caster][EnemyId] = nil

        local EndAttachment = Object.Connection.Attachment1;
        local BaseCFrame = Object.Connection.Attachment0.WorldCFrame;
        local WorldCF = EndAttachment.WorldCFrame;
        EndAttachment.Parent = workspace
        EndAttachment.WorldCFrame = Object.Connection.Attachment0.WorldCFrame;

        local Distance = (BaseCFrame.Position - WorldCF.Position).Magnitude
        local StartCf = CFrame.lookAt(BaseCFrame.Position, WorldCF.Position) * CFrame.new(0, 0, -3)
        local MidPoint = StartCf * CFrame.new(0, 0, -(Distance/2 - 3))

        Object.FireTrail.CurveSize0 = math.random(-6, 7)
        Object.FireTrail.CurveSize1 = math.random(-6, 7)
        Object.FireTrail.Width0 = 0.5
        Object.FireTrail.Width1 = 0

        Effects:Tween(Object.FireTrail, { 0.25, 'Back' }, {Width0 = 0.25, Width1 = 0.25})
        Effects:Tween(Object.FireTrail, { 0.65, 'Elastic' }, {CurveSize0 = 0, CurveSize1 = 0})
        Effects:Tween(Object.Connection, { 0.25, 'Quart' }, {Width0 = 0, Width1 = 0})
        Effects:Tween(EndAttachment, { 0.2, 'Cubic' }, {WorldCFrame = WorldCF})
        
        task.wait(0.15)

        local Time = (Distance / 45) * 0.35
        local FirePart = Effects:Create(VFXAssets.FirePart, 10)
        FirePart.Size *= vector.zero
        FirePart:PivotTo(StartCf)

        Effects:Tween(FirePart, {Time, 'Linear'}, {CFrame = MidPoint, Size = vector.create(0.01, 0.01, Distance)})

        task.wait(Time)
        Effects:Toggle(FirePart, false)
        Effects:Tween(Object.FireTrail, {0.3, 'Sine'}, {Width0 = 0, Width1 = 0})
        Effects:CleanUp(Object, 2)

        Library:Play("Sasuke_FireExplosion", EnemyObject:GetPivot())

        EnemyObject:Hit()
    end

end