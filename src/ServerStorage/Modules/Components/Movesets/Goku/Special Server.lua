--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	--
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name)
	local InMode = Caster:GetEffect("GOKU_MODE_BUFF") ~= nil;

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState('Attacking', Ability:FromData('Attack_State_Time'))
		end,},

		{.15, function()
			if InMode and Context.Target then
				local At = Context.Target:GetPivot() * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0);

				Caster:PivotTo(At);
			end
		end},
	})
end

return Ability
