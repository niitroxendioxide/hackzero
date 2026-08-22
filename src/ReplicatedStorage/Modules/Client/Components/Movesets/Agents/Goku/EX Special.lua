--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local EnemyList = {}
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Caster: Types.Caster) 
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	if not InMode then
		return
	end
	
	EnemyList = {}

	local AllEnemies = Enemies:GetAll()

	local TempList = {}
	for _, Enemy in AllEnemies do
		if (Enemy:GetPivot().Position - Caster:GetPivot().Position).Magnitude < 24 and #TempList < 10 then
			table.insert(TempList, Enemy)
		end
	end

	table.sort(TempList, function(a, b)
		local d_a = (a:GetPivot().Position - Caster:GetPivot().Position).Magnitude
		local d_b = (b:GetPivot().Position - Caster:GetPivot().Position).Magnitude

		return d_a > d_b
	end)

	for _, obj in TempList do
		table.insert(EnemyList, obj:GetId())
	end

	Ability:PushToContextBuffer(EnemyList)
end)


local function Default(Caster: Types.Caster, Target: Types.ClientEnemy, Attack: Types.Sequence)
	
	if (Target == nil) or (not Target:IsAirborne()) then
		local AttackTime = Ability:FromData('Attack_State_Time');	
		Attack:Add(0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
			Ability:PlayAnimation(Caster, 'Goku.Abilities.Special.EX_Default_Kick', {})
		end)
		
		Attack:Add(0.25, function()
			
			local was_hit = false;
			Ability:CreateHitbox(Caster, Vector3.zAxis*-5, vector.create(9, 5, 9), function(Enemy)

				if was_hit == false then
					was_hit = true
					Ability:Effect("Goku_UpliftEffect", Caster);
				end

				Ability:Hit(Caster, Enemy, {
					EffectData = Ability:FromData("Hit_Effect_Data"), 
					Track = 'Characters.Goku.Abilities.Special.LauncherTarget'
				})
			end)

		end)
	else
		local DiskTime, DiskSpeed = Ability:FromData("DiskTime"), Ability:FromData("DiskSpeed")
		local IsAirborne = Caster:IsAirborne()
		local ExtraTime = (not IsAirborne and Ability:FromData("GroundExtraTime") or 0)
		local AttackTime = Ability:FromData('DestructoDiskTime') + ExtraTime

		Attack:Add(0, function()
			local Track = 'Goku.Abilities.Special.DestructoDiskAir'
			local Res = Ability:MatchAirborneHeights(Caster, Target, 1.5, false, 0.175);
			if Res == GameEnum.AirborneMatchState.Raised then
				Track = 'Goku.Abilities.Special.DestructoDiskGround'
				Ability:Effect("Goku_RaiseVfx", Caster)
			end

			Ability:PlayAnimation(Caster, Track, {
				Active_Time = 1,
			})
			
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
		end)

		Attack:Add(0.18 + ExtraTime, function()
			Ability:Effect("Goku_DestructoDisk", Caster, true)
		end)

		Attack:Add(0.5 + ExtraTime, function()
			Ability:Effect("Goku_DestructoDisk", Caster, false, DiskTime, DiskSpeed)
		end)
	end
end

function ModeVersion(Caster: Types.Caster, Target: Types.ClientEnemy, Attack: Types.Sequence)
	if (Target == nil) or (not Target:IsAirborne()) then
		Default(Caster, Target, Attack)
	else
		local AttackTime = Ability:FromData('AngrykamehamehaTime')

		Attack:Add(0, function()
			local Track = 'Goku.Abilities.Special.EX_AngryKamehameha'
			local Res = Ability:MatchAirborneHeights(Caster, Target, 1.5, false, 0.175);
			if Res == GameEnum.AirborneMatchState.Raised then
				Ability:Effect("Goku_RaiseVfx", Caster)
			end

			Ability:PlayAnimation(Caster, Track, {
				Active_Time = 1,
			})
			
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)
		end)

		Attack:Add(0.533, function()
			Ability:Effect("Kamehameha_Beam", Caster, true, CFrame.new(-0.001, 0.321, -3.025), { Time = 0.6, Speed = .45, Length = 75 }, -172)
		end)
	end
end

function Ability:Play(Caster: Types.Caster, _, _, Context: {[any]: any})
	--
	--

	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local Attack = Ability:Begin(Caster, {}, true);

	if InMode then
		ModeVersion(Caster, Context.Target, Attack) -- ModeVersion(Caster, Attack, EnemiesToCycle)
	else
		Default(Caster, Context.Target, Attack)
	end

	Attack:Start()
end

return Ability
