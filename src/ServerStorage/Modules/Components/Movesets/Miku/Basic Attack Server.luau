--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local AbilityClass = require(Classes.Combat.ServerAbility)
local Types = require(Shared.Types.Abilities)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, State, Context): ()
	local M1_Count = (Context.M1_Count :: number)
    local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
    local AttackHitData = Ability:FromData("Hit")

	local Sequence = Ability:Begin(Caster, {
		{0, function()
		end,},
    }, true)

    local DamageMult = Ability:FromData("DamageMult", M1_Count, SkillLevel)
    local DazeMult = Ability:FromData("DazeMult", M1_Count, SkillLevel)

    local HitboxSize = vector.create(6, 6, 18)
    if M1_Count == 2 then
        HitboxSize = vector.create(6, 6, 35)
    end

    AttackHitData.Damage = DamageMult
    AttackHitData.Daze = DazeMult

	for i = 1, 9 do
		local Count = M1_Count + 0.1*i
		local AttackData = Ability:FromData("AttackData", Count)
		if typeof(AttackData) ~= "table" then
			break
		end

		Sequence:Add(AttackData[2], function()
			Caster:LookAtTarget(Context.Enemy)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -HitboxSize.z/2), HitboxSize, function(Enemy) 
				Ability:Hit(Caster, Enemy, AttackHitData)
			end)
		end)
	end

	Sequence:Start()
end

return Ability
