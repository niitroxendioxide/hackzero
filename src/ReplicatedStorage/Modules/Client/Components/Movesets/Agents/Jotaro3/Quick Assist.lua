--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass)

    local Attack_Time = Ability:FromData('Attack_State_Time')
    local Frozen_Time = Ability:FromData('Skill_Freeze_Time')

    Ability:Begin(Caster, {
        {0, function()
            Ability:Effect("JP3_Stand", Caster, {
                At = Vector3.new(0, 0, -3),
                Time = Attack_Time + 0.2,
            })

			local StandModel = workspace.World.Effects:FindFirstChild(Caster:GetId()..'SPstandmodel')
			Ability:PlayAnimation(Caster, 'Jotaro3.Abilities.M1.Stand_4', {
				Fade = .1,
				Active_Time = Attack_Time + .25,
				Model = StandModel,
			})

            self:Effect('Timestop_Screen_Effect', Frozen_Time)
        end},

        {0.25, function()
            Ability:CreateHitbox(Caster, Vector3.zAxis * -4.5, Vector3.new(5, 5, 9), function(Target: Types.Enemy)
				Ability:Effect('Hit', Target)
			end)
        end}
    })
end

return Ability