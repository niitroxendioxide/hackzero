--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()

	local AttackStateTime = Ability:FromData("Attack_State_Time")
    local HitboxSize = Ability:FromData("HitboxSize")
	local HitboxOffset = Ability:FromData("HitboxOffset")
    local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(self.__Name))

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime)
            Caster:Walk(0.25, 0.45)
        end},
        
        {0.27, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy)
                Ability:Hit(Caster, Enemy, HitData)
			end)
		end},
    })
end

return Ability
