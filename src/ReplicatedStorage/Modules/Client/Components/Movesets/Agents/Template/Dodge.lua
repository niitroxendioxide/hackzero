--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass)
	--
	local Animator = Caster:GetAnimator()
	Ability:Save(Caster, 'Side', Ability:Get(Caster, 'Side') == 1 and 0 or 1)

	if Animator:GetTrack('Dash') then
		Animator:Stop('Dash')
	end

	Animator:Play('Dash'..(Ability:Get(Caster, 'Side') == 1 and 'Right' or 'Left'), {Name = 'Dash'})
	Caster:SwitchState('Dashing', .3)
	Caster:ImpulseForward(35, 0.33)
end

return Ability
