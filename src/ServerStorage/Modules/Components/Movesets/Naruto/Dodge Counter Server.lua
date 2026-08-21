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
    local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(self.__Name))
    local ShurikenHitData = Ability:FromData("ShurikenHit", nil, Caster:GetSkillLevel(self.__Name))

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime)
            Caster:Walk(0.25, 0.45)
        end},
        
        {0.33, function()
			local Projectile; do
                Projectile = Ability:CreateMovingHitbox(Caster, Caster:GetPivot(), vector.create(4, 4, 6), 80, 1.25, function(Target)
                    Projectile:Destroy()

                    Ability:Hit(Caster, Target, ShurikenHitData)

                    task.delay((.45 / 1.1), function()
                        local Offset = Caster:GetPivot():ToObjectSpace(Target:GetPivot()).Position
                        Ability:CreateHitbox(Caster, Offset, HitboxSize, function(HitTarget)
                            Ability:Hit(Caster, HitTarget, HitData)
                        end)
                    end)
                end)
			end
		end},
    })
end

return Ability
