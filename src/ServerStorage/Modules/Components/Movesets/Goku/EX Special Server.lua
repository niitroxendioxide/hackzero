--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, Skill_Name: string, State: string, ...)
	--
	local SequenceObj = Ability:Get(Caster, 'Sequence')
	print(State)

	if State ~= 'Begin' then
		Caster:SwitchState('Attacking', 0)
		local _=SequenceObj and SequenceObj:Destroy()

		return;
	end

	local Clock = os.clock()
	local AttackTime = Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', AttackTime)
		end,},

		{.317, AttackTime, function(self)
			if Caster:GetEnergy() <= 0 then
				self:Destroy()

				Ability:Cancel(Caster)
			end

			if (os.clock() - Clock) > Ability:FromData('Hit_Frequency') then
				Caster:UseEnergy(Ability:FromData('Energy_Per_Hit'))

				Clock = os.clock()
				Caster:Walk(Ability:FromData('Walk_Time'))

				Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.ServerEnemyClass)
					Ability:Hit(Caster, Target, {
						Damage = Ability:FromData('Damage_Mult', nil, 1),
						Affliction = 'Physical',
						Stun = .225,
						Daze = Ability:FromData('Daze_Mult', nil, 1),
						Affliction_Buildup = Ability:FromData('Affliction_Buildup', nil, 1)
					})
				end)
			end
		end,},
	})

	Ability:Save(Caster, 'Sequence', Sequence);

	Sequence:After(function()
		Ability:Save(Caster, 'Sequence', nil)
	end)

end

return Ability
