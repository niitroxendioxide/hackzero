--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
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

		{.18, function()
			
			if InMode then
				local Data = Ability:FromData('Sledge_Hammer', nil, SkillLevel)

				Ability:CreateHitbox(Caster, Vector3.zAxis*-3.5, vector.one * 6, function(Enemy: Types.Enemy) 
				
					Ability:Hit(Caster, Enemy, {
						Damage = Data.Damage,
						Affliction = "Physical",
						Stun = Data.StunTime,
						Daze = Data.Daze,
						HitType = "Blunt",
						Knockback = Data.Knockback,
						Affliction_Buildup = Data.Affliction_Buildup,
					})

				end)

			end

		end}
	})
end

return Ability
