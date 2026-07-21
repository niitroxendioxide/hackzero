--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster, _, _, Context:{ read M1_Count: number }): ()

	local Attack_Time = Ability:FromData("Attack_State_Time")

	local TargetHit = false
	local BaseCFrame = nil;
	local Range = Ability:FromData("Clone_Range")
	local HitData = Ability:FromData("Hit")
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{0.225, function()
			BaseCFrame = Caster:GetPivot()
		end},

		{0.275, 0.455, function(self)
			if TargetHit then
				return
			end

			local Alpha = (self.__currentTime - 0.275) / 0.18
			local Offset = CFrame.new(0, 0, -1):Lerp(CFrame.new(0, 0, -(Range + 2)), Alpha)
			local OffsetFromBase = Caster:GetPivot():ToObjectSpace(BaseCFrame) 

			Ability:CreateHitbox(Caster, (OffsetFromBase * Offset).Position, vector.create(6, 6, 4), function(Enemy)
				TargetHit = true

				Ability:Stun(Enemy, 0.4)

				task.delay(0.4, function()
					Ability:Hit(Caster, Enemy, HitData)
				end)
			end)
		end}
	})
end

return Ability
