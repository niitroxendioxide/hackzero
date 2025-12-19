--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Enemy_Stack_Counter = {}
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	--
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name);
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

		{.15, function()
			if InMode and Context.Target then
				local At = Context.Target:GetPivot() * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0);

				Caster:PivotTo(At);
			end
		end},

		{.267, function()
			
			if not InMode then
				local Data = Ability:FromData('Sledge_Hammer', nil, SkillLevel)

				Ability:CreateHitbox(Caster, Vector3.zAxis*-3.5, vector.one * 6, function(Enemy: Types.Enemy) 
					Enemy_Stack_Counter[Enemy] = (Enemy_Stack_Counter[Enemy] or 0) + 1
					if Enemy_Stack_Counter[Enemy] > 3 then
						Enemy_Stack_Counter[Enemy] = 0;

						Enemy:AddEffect(Ability:FromData("Sledge_Hammer_Effect", nil, nil))
					end

					Ability:Hit(Caster, Enemy, {
						Damage = Data.Damage,
						Affliction = "Physical",
						Stun = Data.StunTime,
						Daze = Data.Daze,
						HitType = "Blunt",
						Knockback = Data.Knockback,
						HitsAirborne = true,
						Affliction_Buildup = Data.Affliction_Buildup,
					})

				end)

			elseif InMode then

				local Data = Ability:FromData('Sledge_Hammer', nil, SkillLevel)

				Ability:CreateHitbox(Caster, Vector3.zAxis*-3.5, vector.one * 6, function(Enemy: Types.Enemy) 
					local _, NearestEnemyExcludingHit = Enemies:GetNearestEnemy(Enemy:GetPivot().Position, 100, true, {Enemy})
					local RelativeDirection = if NearestEnemyExcludingHit then
						Enemy:GetPivot():VectorToObjectSpace(CFrame.lookAt(Enemy:GetPivot().Position, NearestEnemyExcludingHit:GetPivot().Position).LookVector)
					else
						vector.create(0, 0, 1)
					

					Ability:Hit(Caster, Enemy, {
						Damage = Data.Damage,
						Affliction = "Physical",
						Stun = Data.StunTime,
						Daze = Data.Daze,
						HitType = "Blunt",
						Knockback = {
							RelativeDirection,
							15,
							0.3,
						},
						Affliction_Buildup = Data.Affliction_Buildup,
					})

				end)

			else error("This shouldn't ever happen really") end

		end}
	})
end

return Ability
