local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ClientAgent)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Assist.Default')
			Ability:Effect("Chihiro_NishikiFish", Caster)
			Ability:Effect("Chihiro_IaiCharge", Caster)
		end,}, 

		{0.417, function()
			local Direction = Caster:GetPivot().LookVector * vector.create(1, 0, 1)
			local Pos = Caster:GetPivot().Position

			Ability:Effect("Chihiro_Dash", Caster, CFrame.lookAlong(Pos, Direction))
			Ability:CreateHitbox(Caster, vector.create(0, 0, -17), vector.create(10, 10, 35), function(Enemy)  
				Ability:Hit(Caster, Enemy, {
					EffectData = {
						Highlight = true,
						HighlightColor = Color3.new(1)
					}
				})
			end);

			local Cast = Effects:CastMapRaycast(Pos, Direction * 35);
			local EndCFrame = CFrame.lookAlong(Pos, Direction) * CFrame.new(0, 0, -35)
			if Cast then
				EndCFrame = CFrame.lookAlong(Cast.Position - Cast.Normal * 2, Direction)
			end

			Ability:Save(Caster, "StartCFrame", EndCFrame)
			Ability:Save(Caster, "GoalCFrame", EndCFrame)
		end},

		{0.417, 0.75, function(self)
			local Diff = 0.75 - 0.417
			local Progress = math.min((self.__currentTime - 0.417) / Diff, 1)
			local Alpha = TweenService:GetValue(Progress, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

			local Start, End = Ability:Get(Caster, "StartCFrame"), Ability:Get(Caster, "GoalCFrame")
			Caster:PivotTo(Start:Lerp(End, Alpha))
		end},
	}, true);

    Sequence:Start()
end

return Ability