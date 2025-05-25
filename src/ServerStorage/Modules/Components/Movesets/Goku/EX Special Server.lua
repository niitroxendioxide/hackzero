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
	if State ~= 'Begin' then
		local _=SequenceObj and SequenceObj:Destroy()

		return;
	end

	local Clock = os.clock()
	local Sequence = Ability:Begin(Caster, {
		{0, function(_: Types.Sequence)
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

		{.317, 10, function(self)
			if (os.clock() - Clock) > (14/60) then
				Clock = os.clock()
				Caster:Walk(2/60)

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
end

return Ability
