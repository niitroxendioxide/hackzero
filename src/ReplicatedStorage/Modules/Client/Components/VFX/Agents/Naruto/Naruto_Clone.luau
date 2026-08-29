---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AnimLib = require(Client.Libraries.Animation)
local Effects = require(Shared.Utility.Effects)

local EffectsLib = require(Client.Libraries.Effects)
local InstanceCache = require(Client.Utility.Effects.InstanceCache)

local Cache = {}

local function TweenCFrame(BaseModel: Model, From: CFrame, To: CFrame, Time: number, Style: string?, Direction: string?)
    local Start = os.clock()
    while (os.clock() - Start) <= Time do
        local Value = (os.clock() - Start) / Time
        local Alpha = TweenService:GetValue(Value, Enum.EasingStyle[Style or 'Quad'], Enum.EasingDirection[Direction or 'Out'])
        BaseModel:PivotTo(From:Lerp(To, Alpha))

        task.wait()
    end

    BaseModel:PivotTo(To)
end

---
return function(Caster: Types.AgentClass, Time: number?, Offset: CFrame?, AnimationData: {
    Id: string, Object: Animation, Speed: number, Weight: number, CFrameTween: {any}, NoSmokeOut: boolean,
    Rasengan: {number},
    FollowTarget: Types.ClientEnemy,
}?): ()
    if Caster == true then
        if AnimationData.Id and Cache[AnimationData.Id] then
            Cache[AnimationData.Id]()
        end

        return
    end
    
    Time = Time or 0.75
    Offset = Offset or CFrame.new()
    AnimationData = AnimationData or {}

    ---
    local PoolId = Caster.__Player_Assigned.UserId .. "naruto_clone_pool"
    local NarutoVfx = Assets.Effects.Agents.Naruto
    local CasterAppearance = Caster:GetAppearance()
    if not InstanceCache:DoesPoolExist(PoolId) then
        local BaseModelClone = CasterAppearance:CloneModel()
        if BaseModelClone:FindFirstChildOfClass("Highlight") then
            while BaseModelClone:FindFirstChildOfClass("Highlight") do
                BaseModelClone:FindFirstChildOfClass("Highlight"):Destroy()
            end
        end

        InstanceCache:CreatePoolFor(PoolId, BaseModelClone, 2, true)
    end

    local ModelClone = InstanceCache:RetrieveFromPool(PoolId)

    ModelClone.PrimaryPart.Anchored = true
    ModelClone.Parent = Effects:GetParent(script.Name)

    local FollowThread: thread = nil;
    if AnimationData.CFrameTween then
        local OriginOffset = AnimationData.OriginOffset or CFrame.new()
        local BaseCFrame = Caster:GetPivot()
        task.spawn(TweenCFrame, ModelClone, BaseCFrame * OriginOffset, BaseCFrame * Offset, AnimationData.CFrameTween[1], AnimationData.CFrameTween[2], AnimationData.CFrameTween[3])
    else 
        ModelClone:PivotTo(Caster:GetPivot() * Offset)

        if AnimationData.Follow or AnimationData.FollowTarget then
            FollowThread = task.spawn(function()
                while true do
                    local FollowedTarget = AnimationData.FollowTarget or Caster

                    ModelClone:PivotTo(FollowedTarget:GetPivot() * Offset)

                    task.wait()
                end
            end)
        end
    end

    if typeof(AnimationData.Object) == 'Instance' and AnimationData.Object:IsA('Animation') then
        --- play track here

        AnimLib:Play(ModelClone, AnimationData.Object, 0, AnimationData.Weight, AnimationData.Speed)
    end
    
    if AnimationData.Rasengan then
        task.delay(0.05, function()
            EffectsLib:Play("Naruto_Rasengan", ModelClone, 'Running', AnimationData.Rasengan[1])
        end)
    end

    for _, BodyPart in ModelClone:GetDescendants() do
        if BodyPart:IsA('Decal') or BodyPart:IsA('BasePart') then
            local Transparency = BodyPart.Transparency;

            BodyPart.Transparency = 1;

            task.delay(0.05, function()
                Effects:Tween(BodyPart, {.1}, {Transparency = Transparency})
            end)

        end
    end

    local SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb, Time + 1.5)

    local Thread = task.delay(.05, function()
        SmokeEffect:PivotTo(ModelClone.Torso.CFrame)

        if not AnimationData.NoSmokeWeld then
            SmokeEffect.Massless = true
            SmokeEffect.Anchored = false
            Effects:Weld(SmokeEffect, ModelClone.PrimaryPart)
        end

        if not AnimationData.NoSmokeIn then
            Effects:Emit(SmokeEffect, true)
        end

        task.wait(Time)

        if FollowThread then
            task.cancel(FollowThread)
        end

        SmokeEffect.Anchored = true;

        if not AnimationData.NoSmokeOut then
            SmokeEffect:PivotTo(ModelClone.Torso.CFrame)
            Effects:Emit(SmokeEffect, true)
        end

        InstanceCache:StoreInPool(PoolId, ModelClone)
    end)

    if AnimationData.Id == nil then
        return
    end

    Cache[AnimationData.Id] = function()
        if Thread ~= coroutine.running() then
            task.cancel(Thread)
        end

        if FollowThread then
            task.cancel(FollowThread)
        end

        local Torso = ModelClone:FindFirstChild("Torso")
        if Torso then
            SmokeEffect:PivotTo(Torso.CFrame)
        end

        Effects:Emit(SmokeEffect, true)
        InstanceCache:StoreInPool(PoolId, ModelClone)
    end
end