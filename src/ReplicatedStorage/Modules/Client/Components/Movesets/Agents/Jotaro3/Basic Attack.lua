--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass)
	Ability:Increase(Agent, 'Count', {Limit = 4})
	local M1_Count = Ability:Get(Agent, 'Count')

	if Ability:Get(Agent, 'M1_Track') then
		Ability:Get(Agent, 'M1_Track'):Stop(0.125)
	end

	--
	local IsStand = M1_Count >= 4
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Agent, {
		{0, function()
			Agent:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			if IsStand then
				Ability:Effect("JP3_Stand", Agent, {
					At = Vector3.new(0, 0, -(2.5 + 0.25*M1_Count)),
					Time = Attack_Time + 0.2,
				})
			end

			local StandModel = workspace.World.Effects:FindFirstChild(Agent.PlayerId..'SPstandmodel')
			local Track = Ability:PlayAnimation(Agent, 'Goku.Abilities.M1.'..Ability:Get(Agent, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .25,
				Model = IsStand and StandModel or nil,
			})

			Ability:Save(Agent, 'M1_Track', Track)
		end,},

		{.1, function()
			Agent:Walk(Ability:FromData('Walk_Time'))
		end,},

		{.18, function()
			local Pos  = IsStand and Vector3.zAxis * -4.5 or Vector3.zAxis*-3
			local Size = IsStand and Vector3.new(5, 5, 9) or Vector3.one * 5
			Ability:CreateHitbox(Agent, Pos, Size, function(Target: Types.ClientEnemy)
				Target:Hit()
				Ability:Effect('Hit', Target)
			end)
		end,},
	})

end

return Ability