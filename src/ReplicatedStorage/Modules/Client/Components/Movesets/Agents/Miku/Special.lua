--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)
local CharactersLib = require(Client.Libraries.Characters)

--
local Ability = AbilityClass.new()

function Ability:Verify(Caster: Types.Caster)
	if Caster:GetState() == "Attacking" and Caster:HasTag("MikuBoostIdleState") then
		return true
	end

	return Caster:GetState() == "Idle"
end

function Ability:Play(Caster: Types.Caster)
	if Ability:Get(Caster, "SingTrack") then
		Ability:Get(Caster, "SingTrack"):Stop()
	end
	
	if Caster:HasTag("MikuBoostIdleState") then
		Caster:SwitchState("Idle", 0)
		Caster:RemoveTag("MikuBoostIdleState")
		Caster:RemoveTag('CharacterStatic')

		return
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local Animation = Ability:PlayAnimation(Caster, "Miku.Abilities.Special.Default", {})

	Ability:Begin(Caster, {
		{0, function(_)
			Caster:AddTag('MikuBoostIdleState', Attack_Time)
			Caster:SwitchState('Attacking', Attack_Time)
			Caster:AddTag('CharacterStatic')
			Ability:Effect("Miku_ToggleLeek", Caster, "Enable")
			Ability:Save(Caster, "SingTrack", Animation)

			task.spawn(function()
				while Caster:GetState() == 'Attacking' do
					local Target = Enemies:GetEnemy(CharactersLib.__Current_Hitting_Target)
					if Target then
						Caster:LookAtTarget(Target, true)
					end	

					task.wait(1 / 24)
				end

				Caster:RemoveTag("MikuBoostIdleState")
				Caster:RemoveTag('CharacterStatic')
				Ability:Effect("Miku_SingAura", Caster, "Disable")

				if Animation and Animation.IsPlaying then
					Animation:Stop(0.1)
				end
			end)
		end,},

		{0.45, function()
			Ability:Effect("Miku_SingAura", Caster, "Enable")
		end},

		{0.75, function()
			Animation:AdjustSpeed(0)
			
		end}
	})
end

return Ability