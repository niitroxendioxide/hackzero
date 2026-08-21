--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 2})
end)

function Ability:Play(Caster: Types.GenericClass)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Caster, 'Template.Abilities.M1.'..Ability:Get(Caster, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{.15, function()
			Caster:Walk(.15, 1.25, true)
		end,},

		{.18, function()
			Ability:CreateHitbox(Caster, Vector3.zAxis*-3, Vector3.one * 5, function(Target: Types.EnemyClass)
				Target:Hit()
				Ability:Effect('Hit', Target)
			end)
		end,},
	})

end

return Ability