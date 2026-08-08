local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Behaviors)

return function(Behavior: Types.EntityBehavior, State: Types.EntityState)
    
    -- // Patterns
    Behavior.DefinePattern('SwordSwings', {
        Skills = {'BasicAttack', 'BasicAttack', 'BasicAttack'},
    })

    Behavior.DefinePattern('SingleMei', {
        Skills = {'Mei'},
        Interruptible = true,
    })

    Behavior.DefinePattern('MeiDash', {
        Skills = {'MeiCloak', 'MeiDash'}
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
    Behavior.Phase('Enraged', function()
        return State.HealthPercent < 50;
    end)

    Behavior.Phase('Struggling', function()
        return State.HealthPercent < 15;
    end)

    --- // Patterns
    Behavior.SetPatterns('Base', {
        'SwordSwings',
        'SingleMei',
    })

    Behavior.SetPatterns('Enraged', {
        'SwordSwings',
        'MeiDash',
        'YuiSpikesTrap',
        'YuiMeiTrap',
    })

    Behavior.SetPatterns('Struggling', {
        'SwordSwings',
        'LastResource',
        'YuiSpikesTrap',
        'YuiMeiTrap',
    })
end
