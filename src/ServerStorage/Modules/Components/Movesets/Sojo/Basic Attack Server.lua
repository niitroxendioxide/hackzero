--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local TableUtil = require(Shared.Utility.Table)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericCaster, _, _, Context): ()
	
	local Target = Context.Target :: Types.ServerAgent
	local HitboxSize = Ability:FromData("Hitbox_Size")
	local HitboxOffset = Ability:FromData("Hitbox_Offset")
	local AttackStateTime = Ability:FromData("Attack_State_Time")
	local HitData = Ability:FromData("Hit")

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", AttackStateTime)
		end},

		{0.3, function()
			Ability:CreateHitbox(Caster, HitboxOffset, HitboxSize, function(Enemy: Types.ServerAgent)
				Ability:Hit(Caster, Enemy, HitData)
			end)
		end}
	})

end

return Ability
