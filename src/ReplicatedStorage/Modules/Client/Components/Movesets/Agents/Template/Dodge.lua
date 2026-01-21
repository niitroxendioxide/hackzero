--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass, _, _, Context)
	--
	local Animator = Caster:GetAnimator()
	--Ability:Save(Caster, 'Side', Ability:Get(Caster, 'Side') == 1 and 0 or 1)
	--(Ability:Get(Caster, 'Side') == 1 and 'Right' or 'Left')

	if Animator:GetTrack('Dash') then
		Animator:Stop('Dash')
	end

	
	local Anim = Context.IsCancel and 'Back' or 'Forth'
	if not Context.IsCancel then
		Ability:Effect("Dodge_VFX", Caster)
	else
		Ability:Effect("Cancel", Caster)
	end

	Animator:Play('Dash' .. Anim, {Name = 'Dash'})
	Caster:SwitchState('Dashing', .3)
	
	local Sign = Context.IsCancel and -1 or 1;
	
	Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
end

return Ability
