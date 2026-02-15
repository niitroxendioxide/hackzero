local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.Caster)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function(_)
			Caster:SwitchState('Attacking', Attack_Time)
			Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Assist.Default')
			Ability:Effect("Chihiro_NishikiFish", Caster)
		end,}, 

		{0.35, function()
			local Direction = Caster:GetPivot().LookVector * vector.create(1, 0, 1)
			local Pos = Caster:GetPivot().Position

			Ability:Effect("Chihiro_Dash", Caster, CFrame.lookAlong(Pos, Direction))
			Ability:CreateHitbox(Caster, vector.create(0, 0, -16), vector.create(10, 10, 32), function(Enemy)  
				Ability:Hit(Caster, Enemy, {
					EffectData = {
						Highlight = true,
						HighlightColor = Color3.new(1)
					}
				})
			end);

			local Cast = Effects:CastMapRaycast(Pos, Direction * 32);
			if Cast then
				Caster:PivotTo(CFrame.lookAlong(Cast.Position - Cast.Normal * 2, Direction))
			else
				Caster:PivotTo(CFrame.lookAlong(Pos, Direction) * CFrame.new(0, 0, -32))
			end
			
		end},
	}, true);

    Sequence:Start()
end

return Ability