--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

-->
local Ability = AbilityClass.new()

local function Default(Caster: Types.Caster, Attack: Types.Sequence)
	local Default_Hit_Data = Ability:FromData('Default', nil, Caster:GetSkillLevel(Ability.__Name))
	Default_Hit_Data.Knockback = Ability:FromData("Knockback");

	Attack:Add(0.25, function()
	
		Ability:CreateHitbox(Caster, Vector3.zAxis*-3, vector.create(5, 5, 6.65), function(Enemy)
			print('so did you hit?')

			Ability:Hit(Caster, Enemy, Default_Hit_Data)
		end).Debug()

	end)
end

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence)

	-- loop through all enemies in an area;

end

function Ability:Play(Caster: Types.Caster)
	--
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local AttackTime = Ability:FromData('Attack_State_Time', InMode and 2 or 1);
	local Attack = Ability:Begin(Caster, {

		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime)
		end},

	}, true);

	if InMode then
		ModeVersion(Caster, Attack)
	else
		Default(Caster, Attack)
	end

	Attack:Start()
end

return Ability
