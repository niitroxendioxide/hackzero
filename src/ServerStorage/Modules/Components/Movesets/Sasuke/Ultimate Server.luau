--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local AttackStateTime = Ability:FromData("Attack_State_Time")
    local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))
    local Hits = {}
    local Left, Right = CFrame.Angles(0, math.rad(38), 0), CFrame.Angles(0, math.rad(-38), 0)

    local function FireballHit(Enemy)
        if Hits[Enemy] == true then
            return
        end

        Hits[Enemy] = true;
        task.delay(Ability:FromData("Hit_Frequency"), function()
            Hits[Enemy] = false;
        end)

        Ability:Hit(Caster, Enemy, HitData)
    end

	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime, true)
            Ability:Effect("Sasuke_DragonFire", {Caster}, true)
        end},

        {0.7, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * Left * CFrame.new(0, 0, -1), vector.create(12, 12, 12), 75, 1, function(Target)
                Object:SetSpeed(20)
                FireballHit(Target)
            end)
        end},

        {1.05, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -1), vector.create(12, 12, 12), 75, 1, function(Target)
                Object:SetSpeed(20)
                FireballHit(Target)
            end)

            Object:Debug()
        end},

        {1.3, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * Right * CFrame.new(0, 0, -1), vector.create(12, 12, 12), 75, 1, function(Target)
                Object:SetSpeed(20)
                FireballHit(Target)
            end)
        end}
    })
end

return Ability
