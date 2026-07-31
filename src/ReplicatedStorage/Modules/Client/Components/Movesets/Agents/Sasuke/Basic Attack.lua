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
	Ability:Increase(Agent, 'Count', {Limit = 3})
end)

function Ability:Play(Caster: Types.GenericClass)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	local Attack_Data = Ability:FromData('Attack_Data')
	local Sequence = Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:PlayAnimation(Caster, 'Sasuke.Abilities.M1.'..M1_Count, {
				Fade = .1,
				Active_Time = Attack_Time + .25,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{1, function()
			if M1_Count == 3 then
				Ability:Effect("KunaiProjectile", Caster, 75, 1, vector.create(4, 4), true)
			end
		end},
	}, true)

	
	for i = M1_Count, M1_Count + 1, 0.1 do
		local TickData = Attack_Data[i]
		if not TickData then
			break
		end

		Ability:UseAttackData(Sequence, Caster, TickData, {
			Size = Ability:FromData("HitboxSize"),
			Offset = Ability:FromData("HitboxOffset"),

			Hit_Function = function(Target)
				Ability:Hit(Caster, Target, {EffectData = {Highlight = true}, NoHitStop = true})
			end
		})
	end

	Sequence:Start()

end

return Ability