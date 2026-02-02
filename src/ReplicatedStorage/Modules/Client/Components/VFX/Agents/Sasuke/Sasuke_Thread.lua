---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)

---
local Cache = {}

---
return function(Caster, EnemyId: number, Type: number): ()
    if not Cache[Caster] then
        Cache[Caster] = {}
    end

    local VFXAssets = Assets.Effects.Agents.Sasuke.KatonThread
    local EnemyObject = Enemies:GetEnemy(EnemyId)
    local CasterModel = Caster:GetModel()

    -- Connect
    if Type == 1 then
        if Cache[Caster][EnemyId] then
            return
        end

        local Arms = {"Right Arm", "Left Arm"}
        local WeldBase = CasterModel[Arms[math.random(1, #Arms)]]
        local Trail = Effects:Create(VFXAssets.TrailPart)
        Trail:PivotTo(WeldBase:GetPivot())

        Effects:Weld(Trail, WeldBase).Name = "threadWeld"

        Trail.Start.Position = vector.create(0, -1, 0)
        Trail.End.Position = vector.zero
        Trail.End.Parent = EnemyObject:GetModel().PrimaryPart
        Cache[Caster][EnemyId] = Trail
    -- Disconnect
    elseif Type == 2 then
        local Object = Cache[Caster][EnemyId]
        Cache[Caster][EnemyId] = nil

        local EndAttachment = Object.Connection.Attachment1;
        local WorldCF = EndAttachment.WorldCFrame;
        EndAttachment.Parent = workspace
        EndAttachment.WorldCFrame = WorldCF;

        Effects:Tween(Object.Connection, {0.25, 'Back'}, {Width0 = 0, Width1 = 0})

    -- Lit up
    elseif Type == 3 then
        local Object = Cache[Caster][EnemyId]

        Cache[Caster][EnemyId] = nil

        local EndAttachment = Object.Connection.Attachment1;
        local BaseCFrame = Object.Connection.Attachment0.WorldCFrame;
        local WorldCF = EndAttachment.WorldCFrame;
        EndAttachment.Parent = workspace
        EndAttachment.WorldCFrame = WorldCF;

        local Distance = (BaseCFrame.Position - WorldCF.Position).Magnitude
        local StartCf = CFrame.lookAt(BaseCFrame.Position, WorldCF.Position)
        local MidPoint = StartCf * CFrame.new(0, 0, -Distance/2)

        Object.FireTrail.CurveSize0 = math.random(-6, 7)
        Object.FireTrail.Width0 = 0.5
        Object.FireTrail.Width1 = 0

        Effects:Tween(Object.FireTrail, {0.25, 'Back'}, {Width0 = 0.25, Width1 = 0.25})
        Effects:Tween(Object.FireTrail, { 0.3, 'Elastic' }, {CurveSize0 = 0})
        Effects:Tween(Object.Connection, {0.25, 'Quart'}, {Width0 = 0, Width1 = 0})
        
        task.wait(0.15)
        local FirePart = Effects:Create(VFXAssets.FirePart, 10)
        FirePart.Size *= vector.create(1, 1, 0)
        FirePart:PivotTo(StartCf)

        Effects:Tween(FirePart, {0.35, 'Quart'}, {CFrame = MidPoint, Size = vector.create(1, 1, Distance)})
        Effects:CleanUp(Object, 2)

        task.delay(0.5, function()
            Effects:Toggle(FirePart, false)

            Effects:Tween(Object.FireTrail, {0.3, 'Sine'}, {Width0 = 0, Width1 = 0})
        end)
    end

end