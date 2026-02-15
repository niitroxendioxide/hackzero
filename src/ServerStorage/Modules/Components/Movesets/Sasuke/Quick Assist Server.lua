--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, _, _, Context)
	--
	
	local HitRate = Ability:FromData("HitRate")
	local LastHit = os.clock()
	
	-- Hitbox data
	local HitData = Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'), true)

		end,},

		{0.3, 0.825, function()
			if (os.clock() - LastHit) < HitRate then
				return
			end

			LastHit = os.clock()

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6), vector.create(12, 12, 19), function(Enemy)  
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end}
	})
end

return Ability
