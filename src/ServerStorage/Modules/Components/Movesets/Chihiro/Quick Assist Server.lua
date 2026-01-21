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
	})
end

return Ability
