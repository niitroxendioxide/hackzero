--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 2})
end)

function Ability:Play(Agent, _, _, Context)
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('AttackData', M1_Count)
	if typeof(Attack_Time) == 'table' then
		Attack_Time = Attack_Time[3]
	end

	local HitboxSize = vector.create(6, 6, 18)
	if M1_Count == 2 then
        HitboxSize = vector.create(6, 6, 35)
    end

	local Sequence = Ability:Begin(Agent, {
		{0, function(_)
			local Track = Ability:PlayAnimation(Agent, 'Miku.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .125,
			})

			Agent:SwitchState('Attacking', Attack_Time)
			Ability:Effect("Miku_ToggleLeek", Agent, "Enable", 2)

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{0.15, function()
			if M1_Count == 2 then
				Ability:Effect("Miku_LeekBeam", Agent, true)
			end
		end},

		{0.7, function()
			if M1_Count == 2 then
				Ability:Effect("Miku_LeekBeam", Agent, false)
			end
		end}
	}, true)

	local EffectData = Ability:FromData("EffectData")
	for i = 1, 9 do
		local Count = M1_Count + 0.1*i
		local AttackData = Ability:FromData("AttackData", Count)
		if typeof(AttackData) ~= "table" then
			break
		end

		Sequence:Add(AttackData[2], function()
			Agent:LookAtTarget(Context.Enemy)
			Ability:CreateHitbox(Agent, vector.create(0, 0, -HitboxSize.z/2), HitboxSize, function(Enemy) 
				Ability:Hit(Agent, Enemy, {EffectData = EffectData})
			end)
		end)
	end

	Sequence:Start()
end

return Ability