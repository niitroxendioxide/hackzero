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


	local KiBlastData = Ability:FromData('Ki_Blast_Hit', nil, SkillLevel)

	local function CreateBlast()
		local Object do
			Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -2.5), vector.create(4, 4), 120, 1, function(Target)  
				Object:Destroy()

				Ability:Hit(Caster, Target, KiBlastData)
			end)
		end
	end

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

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

				CreateBlast()

			else error("This shouldn't ever happen really") end

		end},

		{0.4, function()
			if InMode then
				CreateBlast()
			end
		end},

		{0.517, function()
			if InMode then
				CreateBlast()
			end
		end}


	})
end

return Ability
