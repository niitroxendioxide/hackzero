--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local EnemyList = {}
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeConnection, function(Caster: Types.Caster)  
	EnemyList = {}

	local AllEnemies = Enemies:GetAll()

	local TempList = {}
	for _, Enemy in AllEnemies do
		if (Enemy:GetPivot().Position - Caster:GetPivot().Position).Magnitude < 20 and #TempList < 10 then
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


local function Default(Caster: Types.Caster, Attack: Types.Sequence)
	Attack:Add(0.25, function()
		
		Ability:CreateHitbox(Caster, Vector3.zAxis*-3, vector.create(5, 5, 6.65), function(Enemy)
			Ability:Hit(Caster, Enemy)
		end)

	end)
end

local function ModeVersion(Caster: Types.Caster, Attack: Types.Sequence, EnemiesToCycle: {[any]: any})
	--
	Ability:Effect("Goku_GroundSlam", Caster)

	--
	local Center = Caster:GetPivot().Position

	for idx = 1, #EnemiesToCycle do
		local EnemyObject = Enemies:GetEnemy(EnemiesToCycle[idx])
		local Start = (idx - 1) * 0.25

		Attack:Add(0.75 + Start, function()
			local EnemyPosition = EnemyObject:GetPivot()
			local Direction = CFrame.lookAt(EnemyPosition.Position, Center).LookVector

			local LerpGoal = CFrame.lookAlong(EnemyPosition.Position - Direction*6, Direction)
			Ability:MatchAirborneHeights(Caster, EnemyObject, 0.5)
			Caster:PivotTo(LerpGoal)
		end)

		Attack:Add(0.9 + Start, function()
			Ability:Hit(Caster, EnemyObject, {})
		end)
	end

end

function Ability:Play(Caster: Types.Caster, _, _, Context: {[any]: any})
	--
	local EnemiesToCycle = Context.Buffer ~= nil and (typeof(Context.Buffer[1]) == 'table' and #Context.Buffer[1] > 0) and Context.Buffer[1]
	or #EnemyList > 0 and EnemyList

	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;
	local AttackTime = Ability:FromData('Attack_State_Time', 1);
	if InMode then
		AttackTime = 0.6 + math.max(#EnemiesToCycle - 1, 0) * 0.25
	end

	local Attack = Ability:Begin(Caster, {

		{0, function()
			Caster:SwitchState(Types.CHARACTER_STATES.Attacking, AttackTime)
		end},

	}, true);

	if InMode then
		ModeVersion(Caster, Attack, EnemiesToCycle)
	else
		Default(Caster, Attack)
	end

	Attack:Start()
end

return Ability
