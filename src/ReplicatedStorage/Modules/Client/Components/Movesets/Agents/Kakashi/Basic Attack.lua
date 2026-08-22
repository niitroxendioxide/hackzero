--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 3})
end)

function Ability:Play(Caster: Types.ClientAgent, _, _, Context)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.2)
	end

	local Sequence = Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:PlayAnimation(Caster, 'Kakashi.Abilities.M1.'..M1_Count, {
				Fade = .1,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},
	}, true)
	
	local AttackData = Ability:FromData("Attack_Data")
	for Step = M1_Count, M1_Count + 1, 0.1 do
		local Tick = AttackData[Step];
		if not Tick then
			break
		end

		local Size = vector.create(7, 5, 7)
		local Offset = vector.create(0, 0, -4)

		if Step > 2 and M1_Count == 2 then
			Size = vector.create(12, 5, 7)
		end

		Ability:UseAttackData(Sequence, Caster, Tick, {
			Size = Size,
			Offset = Offset,
			Hit_Function = function(Target)
				Ability:Hit(Caster, Target, {NoHitStop = true})
			end
		})
	end

	Sequence:Start()
end

return Ability