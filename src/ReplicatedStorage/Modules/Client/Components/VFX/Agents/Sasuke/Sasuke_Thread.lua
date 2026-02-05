---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)

---
local Cache = {}

---
return function(Caster, EnemyId: number, Type: number, fn): ()
    if not Cache[Caster] then
        Cache[Caster] = {}
    end

    local VFXAssets = Assets.Effects.Agents.Sasuke.KatonThread
    local SasukeVFX = Assets.Effects.Agents.Sasuke
    local EnemyObject = Enemies:GetEnemy(EnemyId)
    local CasterModel = Caster:GetModel()

    -- Connect
    if Type == 1 then
        if Cache[Caster][EnemyId] then
            return
        end

        local WeldBase = CasterModel.Head
        local Trail = Effects:Create(VFXAssets.TrailPart)
        Trail:PivotTo(WeldBase.CFrame)

        Effects:Weld(Trail, WeldBase).Name = "threadWeld"

        Trail.Start.Position = vector.create(0, -0.25)
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

        Effects:CleanUp(Object, 1)
        Effects:Tween(Object.Connection, {0.25, 'Back'}, {Width0 = 0, Width1 = 0})

    -- Lit up
    elseif Type == 3 then
        local Object = Cache[Caster][EnemyId]

        Cache[Caster][EnemyId] = nil

        local EnemyObject = Enemies:GetEnemy(EnemyId)
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

        local FireballHitVFX = Effects:Create(SasukeVFX.FireballHit, 3.65)
        FireballHitVFX:PivotTo(EndAttachment.WorldCFrame)
        Effects:Emit(FireballHitVFX)

        EnemyObject:Hit()

        task.delay(0.5, function()
            Effects:Toggle(FirePart, false)

            Effects:Tween(Object.FireTrail, {0.3, 'Sine'}, {Width0 = 0, Width1 = 0})
        end)
    end

end