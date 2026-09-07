--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)
local Types = require(Shared.Types.Agents)

--
local Ability = AbilityClass.new()

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 4})
end)

function Ability:Play(Caster: Types.AgentClass)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	--
	local StandSummoned = Caster:GetEffect("StandSummoned")
	local IsStand = M1_Count >= 4 or StandSummoned
	local Attack_Time = Ability:FromData('Attack_State_Time', M1_Count)
	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			if IsStand then
				Ability:Effect("JP3_Stand", Caster, {
					At = Vector3.new(0, 0, -(2.5 + 0.25*M1_Count)),
					Time = Attack_Time + 0.2,
				})
			end

			local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
			local Track = Ability:PlayAnimation(Caster, 'Jotaro3.Abilities.M1.'..(IsStand and 'Stand_' or '')..Ability:Get(Caster, 'Count'), {
				Fade = .1,
				Active_Time = Attack_Time + .25,
				Model = IsStand and StandModel or nil,
			})

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{.1, function()
			Caster:Walk(Ability:FromData('Walk_Time'))
		end,},

		{.2, function()
			local Pos  = IsStand and Vector3.zAxis * -4.5 or Vector3.zAxis*-3
			local Size = IsStand and Vector3.new(5, 5, 9) or Vector3.one * 5
			Ability:CreateHitbox(Caster, Pos, Size, function(Target)
				Ability:Hit(Caster, Target, {
					EffectData = {
						HueShift = if (StandSummoned) then 225 else nil,
						Highlight = true,
						HighlightColor = if (StandSummoned) then Color3.fromRGB(63, 10, 155) else nil,
						Audio = 'General/Effects/Hit_Punch',
					}
				})
			end)
		end,},
	})

end

return Ability