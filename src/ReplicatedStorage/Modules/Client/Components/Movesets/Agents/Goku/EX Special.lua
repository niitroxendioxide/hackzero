--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

local function Default(Caster: Types.Caster, Attack: Types.Sequence)
	Attack:Add(0.25, function()
		
		Ability:CreateHitbox(Caster, Vector3.zAxis*-3, vector.create(5, 5, 6.65), function(Enemy)
			Ability:Hit(Caster, Enemy)
		end)

	end)
end

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence)
	
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
