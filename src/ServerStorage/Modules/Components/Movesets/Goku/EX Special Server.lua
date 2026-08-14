--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

-->
local Ability = AbilityClass.new()

local function Default(Caster: Types.Caster, Target: Types.ServerEnemy, Attack: Types.Sequence)
	local Default_Hit_Data = Ability:FromData('Default', nil, Caster:GetSkillLevel(Ability.__Name))
	local ExtenderMidAir = Ability:FromData('ExtenderMidAir', nil, Caster:GetSkillLevel(Ability.__Name))
	
	if not Target or not Target:IsAirborne() then
		local AttackTime = Ability:FromData('Attack_State_Time', 1);

		Attack:Add(0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
		end)

		Attack:Add(0.25, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(9, 5, 9), function(Enemy)
				if not Enemy:IsAirborne() then
					Enemy:AddTag('DiveKickable', 2.3)
				end

				if Enemy:IsAirborne() and Caster:HasTag('Airborne') then
					Ability:Hit(Caster, Enemy, ExtenderMidAir)
				else
					Ability:Hit(Caster, Enemy, Default_Hit_Data)
				end

				Caster:UpdateMeter('SaiyanSurge', 2);
			end)
		end)
	else
		local DiskTime, DiskSpeed = Ability:FromData("DiskTime"), Ability:FromData("DiskSpeed")
		local Hit = Table.CopyDeep(Ability:FromData("DestructoDisk"))
		local IsAirborne = Caster:HasTag('Airborne')
		local ExtraTime = (not IsAirborne and Ability:FromData("GroundExtraTime") or 0)
		local AttackTime = Ability:FromData('DestructoDiskTime') + ExtraTime

		Attack:Add(0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
		end)

		local Projectile;

		Attack:Add(0.5 + ExtraTime, function()
			local WasHit = {}
			local Side = 1;
			Projectile = Ability:CreateMovingHitbox(Caster, Caster:GetPivot(), vector.create(5, 5, 10), DiskSpeed, DiskTime, function(Enemy)
				if WasHit[Enemy] or not Enemy:IsAirborne() then
					return;
				end

				WasHit[Enemy] = true

				task.delay(0.1, function()
					WasHit[Enemy] = false
				end)

				Hit.Knockback = {
					vector.create(0, 0, Side),
					22,
					0.2,
				}

				for i = 1, 2 do
					Ability:Hit(Caster, Enemy, Hit)

					task.wait(1 / 10)
				end
			end)

			task.delay(DiskTime / 2, function()
				Side = -1
				Projectile:SetSpeed(-DiskSpeed)
			end)
		end)
	end
end

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence, Buffer: { [number]: { number } })
	local EnemyIds = Buffer[1]
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)

	local Center = Caster:GetPivot().Position
	local Hit_Data = Ability:FromData('Hit_Mode', nil, SkillLevel)

	local AttackTime = Ability:FromData('Attack_State_Time', 1);
	if typeof(Buffer[1]) == 'number' then
		AttackTime = 0.75
	else
		AttackTime = 0.6 + math.max(#Buffer[1] - 1, 0) * 0.25
	end

	Attack:Add(0, function()
		Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
	end)
	--
	Attack:After(function()
		for _, Effect in Ability:FromData("SSJ2Buff") do
			Caster:AddEffect(Effect)
		end
	end)

	--
	local ModeDebuff = Ability:FromData('ModeEnemyDebuff')
	for i, EnemyId in EnemyIds do
		local EnemyObject = Enemies:GetEnemy(EnemyId)
		if (EnemyObject:GetPivot().Position - Caster:GetPivot().Position).Magnitude > 25 then
			continue
		end

		Attack:Add(0.35, function()
			local Slam = Ability:FromData('Slam_Hit_Mode', nil, SkillLevel)
			Slam.Stun += (i - 1) * 0.3

			Ability:Hit(Caster, EnemyObject, Slam)
			EnemyObject:AddEffect(ModeDebuff)
		end)

		Attack:Add(0.9 + (i-1) * 0.25, function()
			Hit_Data.Knockback = {
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
	local Attack = Ability:Begin(Caster, {}, true);
	
	if InMode then
		ModeVersion(Caster, Attack, Context.Buffer)
	else
		Default(Caster, Context.Target, Attack)
	end

	Attack:Start()
end

return Ability
