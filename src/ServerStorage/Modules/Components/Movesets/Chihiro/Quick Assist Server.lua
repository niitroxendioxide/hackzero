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
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	
	-- Hitbox data
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'), true)

			Ability:ForOtherAgents(Caster, function(Agent: { read AddEffect: ({any}) -> () }, Data: { IsNext: boolean })  
				for _, Buff in Buffs do
					if Agent:GetEffect(Buff.Tag) then
						Agent:RefreshEffect(Buff.Tag)
						continue
					end

					Agent:AddEffect(Buff)
				end
			end)
		end,},

		{0.417, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -17.5), vector.create(10, 10, 35), function(Enemy)  
				Ability:Hit(Caster, Enemy, HitData)
			end);
		end}
	})
end

return Ability
