local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Behaviors)

return function(Behavior: Types.EntityBehavior, State: Types.EntityState)
    
    -- // Patterns
    Behavior.DefinePattern('SwordSwings', {
        Skills = {'Basic Attack', 'Basic Attack', 'Basic Attack'},
    })

    Behavior.DefinePattern('SingleMei', {
        Skills = {'Mei Cloak'}, -- replace for Mei later
        Cooldown_Time = 8,
        Interruptible = true,
    })

    Behavior.DefinePattern('MeiDash', {
        Skills = {'Mei Cloak', 'MeiDash'}
    })
    
    Behavior.DefinePattern('YuiMeiTrap', {
        Skills = {'YuiTrap', 'Mei'} 
    })

    Behavior.DefinePattern('YuiSpikesTrap', {
        Skills = {'YuiTrap', 'YuiSpikes',}
    })

    Behavior.DefinePattern('LastResource', {
        Skills = {'YuiSpikes', 'MeiMultiCloakDash', 'MeiCharged'},
    })

    --- // Phase changes
    Behavior.Phase('Enraged', 1, function()
        return State.HealthPercent() < 50;
    end)

    Behavior.Phase('Struggling', 2, function()
        return State.HealthPercent() < 15;
    end)

    --- // Patterns
    Behavior.SetBasePatterns({
        { Name = 'SwordSwings', Weight = 1 },
        { Name = 'SingleMei', Weight = 1 },
        --'SingleMei',
    })

    Behavior.SetPatterns('Enraged', {
        { Name = 'SwordSwings', Weight = 1 },
        { Name = 'MeiDash', Weight = 1 },
        { Name = 'YuiSpikesTrap', Weight = 1 },
        { Name = 'YuiMeiTrap', Weight = 1 },
    })

    Behavior.SetPatterns('Struggling', {
        { Name = 'SwordSwings', Weight = 1 },
        { Name = 'LastResource', Weight = 1 },
        { Name = 'YuiSpikesTrap', Weight = 1 },
        { Name = 'YuiMeiTrap', Weight = 1 },
    })
end
