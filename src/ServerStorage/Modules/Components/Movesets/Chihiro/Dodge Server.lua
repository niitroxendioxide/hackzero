--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, _, _, Context): ()
	--

	---
	local Sign = Context.IsCancel and -1 or 1;
	local IsOffCooldown = os.clock() - (Ability:Get(Caster, "LastSlashTime") or 0) > 1.5;
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	Ability:Save(Caster, "LastSlashTime", os.clock())

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Dashing', .15)
			Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
		end},

		{0.1, function()
			if not(IsOffCooldown and Sign == -1) then
				return;
			end

			Ability:CreateHitbox(Caster, vector.create(0, 0, -6.5), vector.create(12, 4, 14), function(Enemy)  
				Ability:Hit(Caster, Enemy, Ability:FromData("Hit", nil, SkillLevel))
			end)
		end},
	})
end

return Ability
