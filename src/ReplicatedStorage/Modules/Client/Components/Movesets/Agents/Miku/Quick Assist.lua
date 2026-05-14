--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent, _, _, Context)
	--
	local EffectData = Ability:FromData("EffectData")
	local Attack_Time = Ability:FromData('Attack_State_Time')

	local Sequence = Ability:Begin(Agent, {
		{0, function(_)
			Ability:PlayAnimation(Agent, 'Miku.Abilities.Assist.Default', {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

			Agent:SwitchState('Attacking', Attack_Time)
			Ability:Effect("Miku_ToggleLeek", Agent, "Enable", 2)
		end,},
	
		{.06, function()
			Agent:Walk(0.25)
		end},

		{0.47, function()
			Ability:Effect("Miku_M1Explosion", Agent, CFrame.new(0, 1.5, 0), 1.2)

			Ability:CreateHitbox(Agent, vector.zero, vector.create(36, 12, 36), function(Enemy)  
				Ability:Hit(Agent, Enemy, {EffectData = EffectData})
			end)
		end},

		{0.85, function()
			if Context.Enemy then
				Ability:Hit(Agent, Context.Enemy, {EffectData = EffectData})
			end
		end}

	}, true)

	Sequence:Start()
end

return Ability