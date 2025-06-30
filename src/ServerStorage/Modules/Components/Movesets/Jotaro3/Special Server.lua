--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local StandUtils = require(ServerStorage.Modules.Packages.Utility.StandUtils)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local IsStandOut = Caster:GetEffect("StandSummoned")
    local Prefix =  IsStandOut and 'S_ON_' or 'S_OFF_'

    local Attack_Time = Ability:FromData(Prefix..'Attack_State_Time')

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', Attack_Time)
        end},

        {.25, function()
            if not IsStandOut then
                StandUtils:CheckAndSummon(self, Caster)
            end

        end}
    })
end

return Ability