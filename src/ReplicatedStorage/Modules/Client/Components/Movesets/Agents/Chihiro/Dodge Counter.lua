--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

-- local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster)

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
	local Sequence = Ability:Begin(Caster, {
		{0, function(_)
			Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Counter.Default', {
				Fade = .1,
				Active_Time = Attack_Time + 0.25,
			})

			Caster:SwitchState('Attacking', Attack_Time)
            Ability:Effect("Chihiro_DodgeCounter", Caster)
            
            Ability:Effect("Slash", Caster, 89, CFrame.new(0, -0.5, 0), false)
		end,},

	}, true);

    ---
    for i = 1, Ability:FromData("Hit_Count") do
        local Delay = (i - 1) * Ability:FromData("Hit_Frequency");

        Sequence:Add(0.16 + Delay, function()
            Ability:CreateHitbox(Caster, vector.create(0, 0, -7), vector.create(13, 8, 13), function(Enemy)  
                Ability:Hit(Caster, Enemy, {EffectData = {
                    Highlight = true,
                }})
            end)
        end)
    end

    Sequence:Start()
end

return Ability