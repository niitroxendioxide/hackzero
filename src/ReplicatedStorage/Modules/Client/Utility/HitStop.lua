-- Constants
local HITSTOP_DURATION = 0.25

--
local HitStop = {}
local ActiveHitStops = {}

function HitStop:Apply(Agent: any, Sequence: any, AnimTrack: AnimationTrack, DurationOverride: number)
    if ActiveHitStops[Agent] then
        task.cancel(ActiveHitStops[Agent])
        ActiveHitStops[Agent] = nil
    end

    if not Sequence or not AnimTrack then
        warn("Missing Sequence or AnimationTrack")
        return
    end

    local originalAnimSpeed = AnimTrack.Speed or 1

    Sequence:Pause()
    AnimTrack:AdjustSpeed(0)

    ActiveHitStops[Agent] = task.delay(HITSTOP_DURATION, function()
        Sequence:Start()
        AnimTrack:AdjustSpeed(originalAnimSpeed)

        ActiveHitStops[Agent] = nil
    end)
end

function HitStop:StopEffect(Effect: Instance, Time: number)

    if ActiveHitStops[Effect] then
        task.cancel(ActiveHitStops[Effect])
        ActiveHitStops[Effect] = nil
    end

    local Array = {}
    for _, Emitter in Effect:GetDescendants() do
        if Emitter:IsA("ParticleEmitter") then
            Array[Emitter] = Emitter.TimeScale
            Emitter.TimeScale = 0
        end
    end

    ActiveHitStops[Effect] = task.delay(Time or HITSTOP_DURATION, function()
        for Emitter, Time in Array do
            Emitter.TimeScale = Time
        end

        ActiveHitStops[Effect] = nil
    end)

end

return HitStop
