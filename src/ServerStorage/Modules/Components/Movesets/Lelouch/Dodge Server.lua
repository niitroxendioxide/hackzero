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
	local Sign = Context.IsCancel and -1 or 1;
	local IsOffCooldown = os.clock() - (Ability:Get(Caster, "LastShotTime") or 0) > Ability:FromData('Fall_Back_Cooldown');
	local SkillLevel = Caster:GetSkillLevel(self.__Name)
	local HitData = Ability:FromData("Hit", nil, SkillLevel)
	Ability:Save(Caster, "LastShotTime", os.clock())

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Dashing', .15)
			Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
		end},
	}, true)

	if IsOffCooldown and Sign == -1 then
		for _, Time in Ability:FromData('Shot_Times') do
			Sequence:Add(Time, function()
				Ability:CreateHitbox(Caster, vector.create(0, 0, -25), vector.create(3, 3, 50), function(Enemy)
					Ability:Hit(Caster, Enemy, HitData)
				end)
			end)
		end
	end

	Sequence:Start()
end

return Ability
