--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

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

local function ModeVersion(Caster: Types.Caster, Target: Types.ServerEnemy, Attack: Types.Sequence)
	if not Target or not Target:IsAirborne() then
		Default(Caster, Target, Attack)
	else
		local AttackTime = Ability:FromData('AngrykamehamehaTime')
		local AngryKameHit = Ability:FromData("AngryKameHit")
		local HitFreq = Ability:FromData('Angry_Kame_Hit_Frequency')
		local HitTags = {}

		Attack:Add(0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
		end)

		Attack:Add(0.5, 1.3, function(Sequence, Delta)
			local Time = math.min((Sequence.__currentTime - 0.5) / 0.6, 1)
			local Current_Hitbox_Size = vector.create(6, 6, Time * 75)
			local Offset  = Vector3.zAxis * -(Current_Hitbox_Size.Z/2);
			
			Ability:CreateHitbox(Caster, Offset, Current_Hitbox_Size, function(Target: Types.ServerEnemy)
				if HitTags[Target] then return end
				HitTags[Target] = true

				task.delay(HitFreq, function()
					HitTags[Target] = nil
				end)
				
 				Ability:Hit(Caster, Target, AngryKameHit)
			end)
		end)
	end
end

function Ability:Play(Caster: Types.Caster, _, _, Context)
	--
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local Attack = Ability:Begin(Caster, {}, true);
	
	if InMode then
		ModeVersion(Caster, Context.Target, Attack)
	else
		Default(Caster, Context.Target, Attack)
	end

	Attack:Start()
end

return Ability
