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

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence, EnemiesToCycle: {[any]: any})
	--
	Attack:Add(0, function()
		local AttackTime = 0.6 + math.max(#EnemiesToCycle - 1, 0) * 0.25
		Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime, true)

		Ability:PlayAnimation(Caster, 'Goku.Abilities.Special.EX_Slam', {
			Active_Time = 0.65,
			Fade = 0.1,
			Weight = 1,
			Speed = 1,
		})
	end)

	Attack:Add(0.35, function()
		Ability:Effect("Goku_GroundSlam", Caster)
	end)

	--
	local HitEffectData = Ability:FromData("Hit_Effect_Data")
	local Center = Caster:GetPivot().Position

	for idx = 1, #EnemiesToCycle do
		local EnemyObject = Enemies:GetEnemy(EnemiesToCycle[idx])
		local Start = (idx - 1) * 0.25

		local Anim_Id_Random = math.random(1, 3)
		Attack:Add(0.75 + Start, function()
			if idx == 1 then
				Ability:Effect("Teleport", Caster)
			end

			local EnemyPosition = EnemyObject:GetPivot()
			local Direction = CFrame.lookAt(EnemyPosition.Position, Center).LookVector
			
			local LerpGoal = CFrame.lookAlong(EnemyPosition.Position - Direction*6, Direction)
			Ability:MatchAirborneHeights(Caster, EnemyObject, 0.75, true)
			Caster:PivotTo(LerpGoal)
			Ability:Effect("Teleport", Caster)

			Ability:PlayAnimation(Caster, 'Goku.Abilities.Special.EX_Mode_'..Anim_Id_Random, {
				Active_Time = 0.75,
				Fade = 0.1,
				Weight = 1,
				Speed = 1,
			})
		end)

		Attack:Add(0.85 + Start, function()
			if Anim_Id_Random > 1 then
				Ability:Effect("Goku_M1_1", Caster)
			else
				Ability:Effect("Goku_M1_4", Caster, 2)
			end
		end)

		Attack:Add(0.9 + Start, function()
			Ability:Hit(Caster, EnemyObject, {EffectData = HitEffectData})
		end)
	end

end

function Ability:Play(Caster: Types.Caster, _, _, Context: {[any]: any})
	--
	local EnemiesToCycle = if #EnemyList > 0 then EnemyList 
		elseif Context.Buffer ~= nil and (typeof(Context.Buffer[1]) == 'table' and #Context.Buffer[1] > 0) then Context.Buffer[1] 
		else {}

	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local Attack = Ability:Begin(Caster, {}, true);

	if InMode then
		ModeVersion(Caster, Attack, EnemiesToCycle)
	else
		Default(Caster, Context.Target, Attack)
	end

	Attack:Start()
end

return Ability
