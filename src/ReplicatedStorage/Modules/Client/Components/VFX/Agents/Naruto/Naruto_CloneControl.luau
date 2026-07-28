---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AnimLib = require(Client.Libraries.Animation)
local Effects = require(Shared.Utility.Effects)

local Clones = {}
local Threads = {}
local Tweens = {}

local function TweenCFrame(BaseModel: Model, From: CFrame, To: CFrame, Time: number, Style: string?, Direction: string?)
    if Time <= 0 then
        BaseModel:PivotTo(To)

        return
    end

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
return function(Id: string, Caster: Types.AgentClass, Time: number?, Offsets: {}, AnimationData: {Object: Animation, Speed: number, Weight: number}?): ()
    Time = Time or 0.75
    Offsets = Offsets or CFrame.new()
    AnimationData = AnimationData or {}

    ---
    if Clones[Id] then
        task.cancel(Threads[Id])

        local Cleanup, Model = Clones[Id].Cleanup, Clones[Id].Model

        if Caster == true then
            Cleanup()

            Clones[Id] = nil
            Tweens[Id] = nil
            return
        end

        for _, k in Tweens[Id] do
            task.cancel(k)
        end

        ---
        local CasterAppearance = Caster:GetAppearance()
        local BaseCFrame = CasterAppearance:GetModel():GetPivot()
        for _, OffsetTween in Offsets do
            local CFOffset = OffsetTween[1]
            local OriginTime = OffsetTween[2]

            table.insert(Tweens[Id], task.delay(OriginTime, TweenCFrame, Model, BaseCFrame, BaseCFrame * CFOffset, OffsetTween[3] or 0, OffsetTween[4], OffsetTween[5]))
        end

        if typeof(AnimationData.Object) == 'Instance' and AnimationData.Object:IsA('Animation') then
            AnimLib:StopTracksWithTag(Model)

            AnimLib:Play(Model, AnimationData.Object, 0, AnimationData.Weight or 1, AnimationData.Speed or 1)
        end

        Threads[Id] = task.delay(Time + .05, function()
            if Clones[Id] ~= nil then
                Clones[Id].Cleanup()
            end

            Tweens[Id] = nil
            Clones[Id] = nil
        end)

        return
    end

    if Tweens[Id] == nil then
        Tweens[Id] = {}
    end
    
    for _, k in Tweens[Id] do
        task.cancel(k)
    end

    local NarutoVfx = Assets.Effects.Agents.Naruto
    local CasterAppearance = Caster:GetAppearance()
    local ModelClone = CasterAppearance:CloneModel()

    ModelClone.PrimaryPart.Anchored = true
    ModelClone.Parent = Effects:GetParent(script.Name)

    local BaseCFrame = CasterAppearance:GetModel():GetPivot()
    for _, OffsetTween in Offsets do
        local CFOffset = OffsetTween[1]
        local OriginTime = OffsetTween[2]

        table.insert(Tweens[Id], task.delay(OriginTime, TweenCFrame, ModelClone, BaseCFrame, BaseCFrame * CFOffset, OffsetTween[3] or 0, OffsetTween[4], OffsetTween[5]))
    end

    if typeof(AnimationData.Object) == 'Instance' and AnimationData.Object:IsA('Animation') then
        AnimLib:Play(ModelClone, AnimationData.Object, 0, AnimationData.Weight or 1, AnimationData.Speed or 1)
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

    ---
    task.delay(0.05, function()
        local SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb, 2)
        SmokeEffect:PivotTo(ModelClone.Torso.CFrame)
        Effects:Emit(SmokeEffect, true)
    end)

    Clones[Id] = {
        Model = ModelClone,
        Cleanup = function()
            local SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb, 2)
            SmokeEffect:PivotTo(ModelClone.Torso.CFrame)
            Effects:Emit(SmokeEffect, true)
            ModelClone:Destroy()
        end
    }

    Threads[Id] = task.delay(Time + .05, function()
        if Clones[Id] ~= nil then
            Clones[Id].Cleanup()
        end

    end)
end