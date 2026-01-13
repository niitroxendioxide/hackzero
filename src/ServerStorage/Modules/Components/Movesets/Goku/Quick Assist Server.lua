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
	
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local HitData = Ability:FromData("Hit_Data", nil, SkillLevel)
	
	-- Hitbox data
	local Current_Hitbox_Size = Vector3.new(7, 7, 9)
	local HitTags = {}

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'), true)
		end,},

		-- kamehameha hitbox
		{1, 2.5, function(Sequence, delta: number)
			Current_Hitbox_Size = Current_Hitbox_Size + (Vector3.zAxis * delta * 60 / 0.8)

			local Offset  = Vector3.zAxis * -(Current_Hitbox_Size.Z/2 - 0.5);
			Ability:CreateHitbox(Caster, Offset, Current_Hitbox_Size, function(Target: Types.Enemy)
				if HitTags[Target] then return end
				HitTags[Target] = true

				task.delay(Ability:FromData('Hit_Frequency'), function()
					HitTags[Target] = nil
				end)
				
 				Ability:Hit(Caster, Target, HitData)

			end)
		end},
	})
end

return Ability
