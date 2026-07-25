--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local World = require(ReplicatedStorage.Modules.Shared.World)
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
	local FinalHit = Ability:FromData("Final")

	local HitList = {}
	local Released = false;
	local Time = Ability:FromData("Length");
	local Limit = Ability:FromData("Limit");

	local function ReleaseRasengan(Enemy: Types.ServerEnemy)
		if Released then
			return;
		end
		
		Caster:SwitchState("Attacking", 0.45)

		task.delay(0.13 / (Ability:FromData("Speed") * Ability:FromData("Animation_Speed") * World:GetSpeed()), function()
			Caster:ImpulseForward(-45, 0.2)
		end)

		Released = true

		local UsedId = Enemy and Enemy:GetId()
		for GrabbedEnemy in HitList do
			GrabService:ForceStopGrab(GrabbedEnemy)
			if GrabbedEnemy:GetId() == UsedId then continue end

			task.spawn(function()
				for i = 1, HitCount do
					Ability:Hit(Caster, GrabbedEnemy, HitCount == i and FinalHit or HitData)

					task.wait(1 / 8)
				end
			end)
		end

		if not Enemy then
			return
		end

		for i = 1, HitCount do
			Ability:Hit(Caster, Enemy, HitCount == i and FinalHit or HitData)

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

		{1.2, 1.2 + Time, function(self)
			if Released then
				return;
			end

			local IsActive = Caster:IsActive()
			if not IsActive and not HitList[Context.Target] then
				Caster:LookAtTarget(Context.Target)
			end

			Ability:CreateHitbox(Caster, Offset, Size, function(Enemy)
				if HitList[Enemy] then
					return
				end

				local CurrentCount = Table:GetDictLength(HitList)
				if CurrentCount >= Limit then
					ReleaseRasengan(Enemy)
					Caster:Walk(1 / 60, 1, true)

					return;
				end

				if not HitList[Enemy] then
					HitList[Enemy] = true

					GrabService:GrabEnemy(Caster, Enemy, 2, CFrame.new(0.3, 0, -(4 + CurrentCount * 2)))
				end
			end)
		end},

		{1.2 + Time, function()
			ReleaseRasengan()
		end}
	})
end

return Ability
