--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, State: Types.InputState)
	--
    local Release = State == 'End'
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

    if Ability:Get(Caster, 'plrSequence') or Release then
        local Sequence = Ability:Get(Caster, 'plrSequence')
        if Sequence then
            Sequence:Destroy()
        end

        Caster:SwitchState('Attacking', 0)
        Ability:Save(Caster, 'plrSequence', nil)

        return
    end

    if not Caster:GetEffect('StandSummoned') then
        return
    end

    local Clock = os.clock()
    local AttackTime =  Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', AttackTime)
		end,},

		{.35, AttackTime, function(self)
            if Caster:GetEnergy() <= Ability:FromData('Energy_Per_Hit') or not Caster:GetEffect('StandSummoned') then
				self:Destroy()

				Ability:ForceRelease(Caster)
			end

			if (os.clock() - Clock) < Ability:FromData('Hit_Frequency') then
                return
			end

            Caster:UseEnergy(Ability:FromData('Energy_Per_Hit'))
            Caster:Walk(Ability:FromData('Walk_Time'))
            Clock = os.clock()

			Ability:CreateHitbox(Caster, Vector3.zAxis*-4,  vector.create(5, 5, 9), function(Target: Types.Target)
				Ability:Hit(Caster, Target, {
                    Damage = Ability:FromData('Damage_Mult', nil, SkillLevel),
                    Affliction = 'Energy',
                    Stun = .225,
                    Daze = Ability:FromData('Daze_Mult', nil, SkillLevel),
                    Knockback = Ability:FromData('Knockback'),
                    Affliction_Buildup = Ability:FromData('Affliction_Buildup', nil, SkillLevel)
                })
			end)
		end,},
	})

    Ability:Save(Caster, 'plrSequence', Sequence)
end

return Ability
