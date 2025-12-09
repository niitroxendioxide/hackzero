-- Constants
local HITSTOP_DURATION = 4/60

--
local HitStop = {}
local ActiveHitStops = {}

function HitStop:Apply(Agent: any, Sequence: any, AnimTrack: AnimationTrack, DurationOverride: number)
    if not Sequence or not AnimTrack then
        warn("Missing Sequence or AnimationTrack")
        return
    end

    if ActiveHitStops[Agent] then
        task.cancel(ActiveHitStops[Agent].Thread)
    end
    
    local originalAnimSpeed = ActiveHitStops[Agent] and ActiveHitStops[Agent].OriginalSpeed or (AnimTrack.Speed or 1)

    Sequence:Pause()
    AnimTrack:AdjustSpeed(0)

    ActiveHitStops[Agent] = {
        OriginalSpeed = originalAnimSpeed,
        Thread = task.delay(DurationOverride or HITSTOP_DURATION, function()
            Sequence:Start()
            AnimTrack:AdjustSpeed(ActiveHitStops[Agent].OriginalSpeed)

            ActiveHitStops[Agent] = nil
        end)
    }
end

function HitStop:StopEffect(Effect: Instance, Time: number)
    if typeof(Effect) ~= 'Instance' then
        return
    end

    if ActiveHitStops[Effect] then
        return
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
