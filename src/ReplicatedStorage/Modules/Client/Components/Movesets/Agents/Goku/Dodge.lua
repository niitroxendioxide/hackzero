--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Agent: Types.AgentClass)
	--
	local Animator = Agent:GetAnimator()
	Ability:Save(Agent, 'Side', Ability:Get(Agent, 'Side') == 1 and 0 or 1)
	
	if Animator:GetTrack('Dash') then	
		Animator:Stop('Dash')
	end
	
	Animator:Play('Dash'..(Ability:Get(Agent, 'Side') == 1 and 'Right' or 'Left'), {Name = 'Dash'})
	Agent:SwitchState('Dashing', .3)
	Agent:ApplyImpulse(Agent:GetPivot().LookVector * 75)
end

return Ability
