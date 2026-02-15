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
	
	local Buffs = Ability:FromData("Buffs")
	local Hit =  Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name))
	
	-- Hitbox data
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'), true)

			Ability:ForOtherAgents(Caster, function(Agent: { read AddEffect: ({any}) -> () }, Data: { IsNext: boolean })  
				for _, Buff in Buffs do
					Agent:AddEffect(Buff)
				end
			end)
		end,},

		{0.3, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -16), vector.create(10, 10, 32), function(Enemy)  
				Ability:Hit(Caster, Enemy, Hit)
			end);
		end}
	})
end

return Ability
