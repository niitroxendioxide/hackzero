--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

-->
local Ability = AbilityClass.new()

local function Default(Caster: Types.Caster, Attack: Types.Sequence)
	local Default_Hit_Data = Ability:FromData('Default', nil, Caster:GetSkillLevel(Ability.__Name))
	Default_Hit_Data.Knockback = Ability:FromData("Knockback");

	Attack:Add(0.25, function()
	
		Ability:CreateHitbox(Caster, Vector3.zAxis*-3, vector.create(5, 5, 6.65), function(Enemy)
			Ability:Hit(Caster, Enemy, Default_Hit_Data)
		end)

	end)
end

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence, Buffer: { [number]: { number } })
	local EnemyIds = Buffer[1]
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	local Center = Caster:GetPivot().Position
	local Hit_Data = Ability:FromData('Hit_Mode', nil, SkillLevel)

	for i, EnemyId in EnemyIds do
		local EnemyObject = Enemies:GetEnemy(EnemyId)
		if (EnemyObject:GetPivot().Position - Caster:GetPivot().Position).Magnitude > 25 then
			continue
		end

		Attack:Add(0.35, function()
			local Slam = Ability:FromData('Slam_Hit_Mode', nil, SkillLevel)
			Slam.Stun += (i - 1) * 0.3

			Ability:Hit(Caster, EnemyObject, Slam)
		end)

		Attack:Add(0.9 + (i-1) * 0.25, function()
			Hit_Data.Knocback = {
				EnemyObject:GetPivot():VectorToObjectSpace(CFrame.lookAt(EnemyObject:GetPivot().Position, Center).LookVector),
				25, -- strength
				0.3 -- time
			}

			Ability:Hit(Caster, EnemyObject, Hit_Data)
		end)
	end

end

function Ability:Play(Caster: Types.Caster, _, _, Context: { Buffer: {any | {number}} })
	--
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local AttackTime = Ability:FromData('Attack_State_Time', 1);
	if InMode then
		AttackTime = 0.6 + math.max(#Context.Buffer[1] - 1, 0) * 0.25
	end

	local Attack = Ability:Begin(Caster, {
		
		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime)
		end},
		
	}, true);
	
	if InMode then
		Caster:AddTag("Invulnerability", AttackTime)
		ModeVersion(Caster, Attack, Context.Buffer)
	else
		Default(Caster, Attack)
	end

	Attack:Start()
end

return Ability
