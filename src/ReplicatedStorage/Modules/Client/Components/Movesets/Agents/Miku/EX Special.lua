--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Enemies = require(Shared.Libraries.Enemies)
local CharactersLib = require(Client.Libraries.Characters)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Verify(Caster: Types.Caster)
	if Caster:GetState() == "Attacking" and Caster:HasTag("MikuBoostIdleState") then
		return true
	end

	return Caster:GetState() == "Idle"
end


function Ability:Play(Caster)
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
	local Animation = Ability:PlayAnimation(Caster, "Miku.Abilities.Special.EX", {})
	local Attack_Time = Ability:FromData('Attack_State_Time')
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

				Ability:Effect("Miku_ToggleLeek", Caster, "Enable", 1)
				Caster:RemoveTag("MikuBoostIdleState")
				Caster:RemoveTag('CharacterStatic')
				Ability:Effect("Miku_SingAura", Caster, "Disable")

				if Animation and Animation.IsPlaying then
					Animation:Stop(0.1)
				end
			end)

		end,},

		{0.6, function()
			Ability:Effect("Miku_SingAura", Caster, "Enable", true)
		end},

		{0.7, function()
			Animation:AdjustSpeed(0)
		end}

	})
end

return Ability