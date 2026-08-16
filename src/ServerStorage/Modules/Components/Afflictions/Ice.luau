----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage.Modules.Shared
local Libraries = ServerStorage.Modules.Libraries

local Rng = Random.new()

local Replicator = require(Libraries.Replicator)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Abilities)

const FROSTBITE_DURATION = 10;

return function(Target: Types.ServerEnemy, Data: { read Damage: number }, Cleanup: () -> ())
    if Target:IsFrozen() then
        return
    end

    local Frozen_Duration = Rng:NextNumber(2, 3);

    Target:SwitchState('Frozen', Frozen_Duration)
    Replicator:Effect("AfflictionBurst", {Target:GetId(), GameEnum.Afflictions.Ice, false, Frozen_Duration}, true)

    local Thread = task.delay(Frozen_Duration, function()
        ---
        Target:TakeDamage(Data.Damage)
        Replicator:Effect("AfflictionBurst", {Target:GetId(), GameEnum.Afflictions.Ice, true, Data.Damage}, true)

        ---
        
        if Target:GetEffect('Frostbite') then
            Target:RemoveEffect('Frostbite')
        end

        Target:AddEffect({
            Tag = 'Frostbite',
            Type = 'Critical_Defense',
            Value = -0.1,
            Time = FROSTBITE_DURATION,
        })

        task.wait(FROSTBITE_DURATION)
        Cleanup()
    end)

    return {
        Max_Damage = Data.Damage,
        Thread = Thread,
        Max_Time = FROSTBITE_DURATION + Frozen_Duration,
        Started = os.clock(),
    }
end