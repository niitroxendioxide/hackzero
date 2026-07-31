--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()


local function Default(Caster: Types.Caster, Attack: Types.Sequence)
    local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
    local DefaultHitData = Ability:FromData("Default_Hit_Data", nil, SkillLevel)

    local function Hit(self: Types.Sequence)
        if self.__currentTime > 0.32 then
            DefaultHitData.Knockback = Ability:FromData("Last_Knockback")
        end

        Ability:CreateHitbox(Caster, vector.zero, vector.one * 14, function(Enemy)  
            Ability:Hit(Caster, Enemy, DefaultHitData)
        end)
    end

    for i = 1, 3 do
        Attack:Add(0.25 + i * 0.033, Hit)
    end
end

local function ModeVersion(...)
    Default(...)
end

function Ability:Play(Caster, _, _, Context)
    local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil

    local Sequence = Ability:Begin(Caster, {
        
        {0, function() 
            Caster:SwitchState(Types.CHARACTER_STATES.Attacking, Ability:FromData("Attack_State_Time"))
        end}

    }, true)

    if InMode then
        Default(Caster, Sequence)
    else
        ModeVersion(Caster, Sequence)
    end

    Sequence:Start()
end


return Ability