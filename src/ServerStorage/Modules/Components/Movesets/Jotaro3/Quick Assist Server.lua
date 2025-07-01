--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, _, _, Data)
    local Target = Data.Target

    local SkillLevel = Caster:GetSkillLevel(self.__Name)
    local Frozen_Time = Ability:FromData('Skill_Freeze_Time')

    Ability:Begin(Caster, {
        {0, function()
            Target:SetWorldSpeed(0, Frozen_Time)
        end},

        {0.25, function()
            Ability:CreateHitbox(Caster, Vector3.zAxis * -4.5, Vector3.new(5, 5, 9), function(Target: Types.Enemy)
				local Result = Ability:Hit(Caster, Target, {
					Damage = Ability:FromData('Damage_Mult', nil, SkillLevel),
					Affliction = 'Energy',
					Affliction_Buildup = Ability:FromData('Affliction_Buildup', nil, SkillLevel),
					Stun = 0.4,
					Daze = Ability:FromData('Daze_Mult'),
				})

				if Result.Hit_Type == 'Entity' then
					local Damage = Result.Damage

					Caster:UpdateMeter('Stand', Damage * 0.01)
				end
			end)
        end}
    })
end

return Ability
