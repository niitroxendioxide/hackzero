--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local GrabService = require(Services.Combat.GrabService)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()

	local Attack_Time = Ability:FromData("Attack_State_Time")

	local HitData = Ability:FromData("Hit")
	local Offset, Size = Ability:FromData("Hitbox_Offset"), Ability:FromData("Hitbox_Size")
	local HitCount = Ability:FromData("Hit_Count")

	local HitList = {}
	local Released = false;
	local Limit = 1;

	local function ReleaseRasengan(Enemy: Types.ServerEnemy)
		if Released then
			return;
		end

		Released = true

		for GrabbedEnemy in HitList do
			GrabService:ForceStopGrab(GrabbedEnemy)

			task.spawn(function()
				for i = 1, HitCount do
					Ability:Hit(Caster, GrabbedEnemy, HitData)

					task.wait(1 / 8)
				end
			end)
		end

		if not Enemy then
			return
		end

		for i = 1, HitCount do
			Ability:Hit(Caster, Enemy, HitData)

			task.wait(1 / 8)
		end
	end

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{1.2, function()
			Caster:Walk(2, 1.15, true)
		end},

		{1.2, 3.2, function(self)
			if Released then
				return;
			end

			local IsActive = Caster:IsActive()
			if not IsActive and not HitList[Context.Target] then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:CreateHitbox(Caster, Offset, Size, function(Enemy)
				if Table:GetDictLength(HitList) > Limit then
					ReleaseRasengan(Enemy)
					Caster:Walk(1 / 60, 1, true)

					return;
				end

				if not HitList[Enemy] then
					HitList[Enemy] = true

					GrabService:GrabEnemy(Caster, Enemy, 2, CFrame.new(0.265, 0, -4))
				end
			end)
		end},

		{3.2, function()
			ReleaseRasengan()
		end}
	})
end

return Ability
