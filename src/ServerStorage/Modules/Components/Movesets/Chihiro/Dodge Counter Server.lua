--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster, _, _, Context)
    local Sequence = Ability:Begin(Caster, {
        
        {0, function() 
            Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Ability:FromData("Attack_State_Time"))
        end},

    }, true);

    ---
    local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))

    for i = 1, Ability:FromData("Hit_Count") do
        local Delay = (i - 1) * Ability:FromData("Hit_Frequency");

        Sequence:Add(Delay, function()
            Ability:CreateHitbox(Caster, vector.create(0, 0, -7), vector.create(13, 8, 13), function(Enemy)  
                Ability:Hit(Caster, Enemy, HitData)
            end)
        end)
    end

    Sequence:Start()
end


return Ability