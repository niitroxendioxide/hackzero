---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Enemies = require(Shared.Libraries.Enemies)
local World = require(Shared.World)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffLibrary = require(Client.Libraries.Effects)

---
local Cache = {}

---
return function(
    Caster: Types.Caster,
    State: boolean,
    ...
): ()
    local GokuAssets = Assets.Goku;
    local Args = {...}

    if State then
        local RightArm = Caster:GetModel():FindFirstChild('Right Arm')
        local DestructoDisk = Effects:Create(GokuAssets.DestructoDisk, 5)
        DestructoDisk:PivotTo(CFrame.lookAt(RightArm.Position + vector.create(0, 1.4, 0), Caster:GetPivot().LookVector))
        DestructoDisk:ScaleTo(0.001)
        
        Effects:TweenModel(DestructoDisk, 1, 0.2, 'Quad')

        ---
        local Thread = task.spawn(function()
            while true do
                local CurrentArmCFrame = CFrame.lookAt(RightArm.Position + vector.create(0, 1.4, 0), Caster:GetPivot().LookVector);
                DestructoDisk:PivotTo(CurrentArmCFrame)

                task.wait()
            end
        end)

        Cache[Caster] = {
            DestructoDisk,
            Thread
        }
    else
        local CasterCache = Cache[Caster]
        if not CasterCache then
            return
        end

        local Time = Args[1];
        local Speed = Args[2];
        local Disk = CasterCache[1];
        
        if typeof(CasterCache[2]) == 'thread' then
            task.cancel(CasterCache[2])
        end

        local OriginCFrame = Caster:GetPivot()
        local ExtraHeight = Caster:GetAppearance():GetAddedHeight()

        Disk:PivotTo(OriginCFrame * CFrame.new(0, ExtraHeight, 0))

        local Params = World:GetEnemyColliderParams(true)
        local Side = 1;
        local ActiveSpeed = Speed;
        local Hit = {}

        local BasePivot = Disk:GetPivot() * CFrame.new(0, -ExtraHeight, 0)
        local Connection; Connection = RunService.Heartbeat:Connect(function(Delta: number)
            local CurrentExtraHeight = Caster:GetAppearance():GetAddedHeight()
            local End = OriginCFrame * CFrame.new(0, CurrentExtraHeight, math.min(-ActiveSpeed * Time * Side, 0))

            local Pivot = CFrame.lookAt(Disk:GetPivot().Position, End.Position)
            local Step = CFrame.new(0, 0, -(ActiveSpeed * Delta))
            Disk:PivotTo(Pivot * Step)
            BasePivot = (BasePivot * CFrame.new(0, 0, -ActiveSpeed * Delta * Side))

            ---

            local PartBounds = workspace:GetPartBoundsInBox(BasePivot * CFrame.new(0, 0, -(ActiveSpeed * Delta * 0.5)), vector.create(5, 5, Delta * 10), Params)
			for _, Part in PartBounds do
                if Part:HasTag('Invulnerability') or Hit[Part] then
                    continue
                end

                Hit[Part] = true
                task.delay(0.1, function()
                    Hit[Part] = false
                end)

                local Target = Enemies:GetFromCollider(Part)

                if Target and Target:IsAirborne() then
                    task.spawn(function()
                        for i = 1, 2 do
                            EffLibrary:Play("Hit", Target, {Emitter = 'AkaHitVFX', HueShift = 38, Highlight = true})
                            Target:Hit()

                            task.wait(1 / 10)
                        end
                    end)
                end
            end
        end)

        local Distance = (5 / math.abs(ActiveSpeed))
        task.delay(Time - Distance, function()
            Connection:Disconnect()
            Effects:Tween(Disk.Main, { 0.1 }, {Size = vector.zero})
            Effects:Toggle(Disk, false)
            Effects:Emit(Disk.Main.Vanish, true)
            Effects:CleanUp(Disk, 1)
        end)

        task.delay(Time / 2, function()
            Side *= -1;
        end)
    end

end