--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass, _, _, Context)
	local Attack_Time = Ability:FromData("Attack_State_Time")

	local TargetHit = false
	local BaseCFrame = nil
	local CloneToken = {}
	local Range = Ability:FromData("Clone_Range")

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, "Naruto.Abilities.Special.CloneJutsu", {Active_Time = 0.5})
			Caster:SwitchState('Attacking', Attack_Time)
		end},

		{0, 0.225, function()
			Caster:LookAtTarget(Context.Target)
		end},

		{0.225, function()
			BaseCFrame = Caster:GetPivot()
			local Object = Animation:GetAnim('Characters.Naruto.Abilities.Special.CloneDive')
			Ability:Effect('Naruto_CloneControl', CloneToken, Caster, 1.2, {{CFrame.new(0, 0, -5), 0}, {CFrame.new(0, 0, -Range), .2, 0.183, 'Quad'}}, {Object = Object})
		end},

		{0.275, 0.455, function(self)
			if TargetHit then
				return
			end

			local Alpha = (self.__currentTime - 0.275) / 0.18
			local Offset = CFrame.new(0, 0, -1):Lerp(CFrame.new(0, 0, -(Range + 2)), Alpha)
			local OffsetFromBase = Caster:GetPivot():ToObjectSpace(BaseCFrame) 

			Ability:CreateHitbox(Caster, (OffsetFromBase * Offset).Position, vector.create(6, 6, 4), function(Enemy: Types.EnemyClass)
				if not TargetHit then
					local Object = Animation:GetAnim('Characters.Naruto.Abilities.Special.CloneGrab')
					Ability:Effect('Naruto_CloneControl', CloneToken, Caster, 1.2, {{Offset * CFrame.new(0, 0, 2.5), 0, 0.15, 'Quad'}}, {Object = Object})
				end

				TargetHit = true

				task.delay(0.4, function()
					Ability:Hit(Caster, Enemy, {})
				end)
			end)
		end}
	})
end

return Ability
