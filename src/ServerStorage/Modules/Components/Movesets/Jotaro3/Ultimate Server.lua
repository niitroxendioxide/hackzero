--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local StandUtils = require(ServerStorage.Modules.Packages.Utility.StandUtils)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local Attack_Time = Ability:FromData('Attack_State_Time')
    local SkillLevel = Caster:GetSkillLevel(self.__Name)

    Caster:UpdateMeter('Stand', 100)
    StandUtils:CheckAndSummon(self, Caster)

    local Range = Ability:FromData('Range', nil, SkillLevel)
    local Duration = Ability:FromData('Duration', nil, SkillLevel)

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', Attack_Time)
        end},

        {0.35, function()
            Ability:Effect('Timestop_Effect', {Caster, 'Jotaro3', Duration}, function(Player, Agent)
                return (Agent:GetPivot().Position - Caster:GetPivot().Position).Magnitude <= Range
            end)
        end},

        {.433, function()
            Ability:CreateHitbox(Caster, Vector3.zero,Vector3.one * Range, function(Target)
                if tostring(Target) ~= 'EnemyClass' then
                    return
                end

                local InRange = (Target:GetPivot().Position - Caster:GetPivot().Position).Magnitude <= Range
                if not InRange then
                    return
                end

                Target:SetWorldSpeed(0, Duration)
            end)
        end}
    })
end

return Ability