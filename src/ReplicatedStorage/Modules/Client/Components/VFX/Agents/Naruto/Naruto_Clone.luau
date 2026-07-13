---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AnimLib = require(Client.Libraries.Animation)
local Effects = require(Shared.Utility.Effects)

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
return function(Caster: Types.AgentClass, Time: number?, Offset: CFrame?, AnimationData: {Object: Animation, Speed: number, Weight: number, CFrameTween: {any}}?): ()
    Time = Time or 0.75
    Offset = Offset or CFrame.new()
    AnimationData = AnimationData or {}

    ---
    local NarutoVfx = Assets.Effects.Agents.Naruto
    local CasterAppearance = Caster:GetAppearance()
    local ModelClone = CasterAppearance:CloneModel()

    ModelClone.PrimaryPart.Anchored = true
    ModelClone.Parent = Effects:GetParent(script.Name)

    if AnimationData.CFrameTween then
        local OriginOffset = AnimationData.OriginOffset or CFrame.new()
        local BaseCFrame = CasterAppearance:GetModel():GetPivot()
        task.spawn(TweenCFrame, ModelClone, BaseCFrame * OriginOffset, BaseCFrame * Offset, AnimationData.CFrameTween[1], AnimationData.CFrameTween[2], AnimationData.CFrameTween[3])
    else 
        ModelClone:PivotTo(CasterAppearance:GetModel():GetPivot() * Offset)
    end

    if typeof(AnimationData.Object) == 'Instance' and AnimationData.Object:IsA('Animation') then
        --- play track here

        AnimLib:Play(ModelClone, AnimationData.Object, 0, AnimationData.Weight, AnimationData.Speed)
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

    task.delay(.05, function()
        local SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb, Time + 1.5)
        SmokeEffect:PivotTo(ModelClone.Torso.CFrame)
        Effects:Emit(SmokeEffect, true)

        task.wait(Time)

        SmokeEffect:PivotTo(ModelClone.Torso.CFrame)
        Effects:Emit(SmokeEffect, true)
        ModelClone:Destroy()
    end)
end