--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass, _,_, Context): ()
    local AttackTime = Ability:FromData('Attack_State_Time')
    local Enemy = Context.Enemy

    local Current_Hitbox_Size = Vector3.new(7, 7, 9)
    local HitTags = {}
    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackTime, true)
            Ability:PlayAnimation(Caster, 'Goku.Abilities.Assist.Default', {})
            
            Ability:Effect('Kamehameha_Beam', Caster, false)
        end,},

        {.975, function()
            Caster:LookAtTarget(Enemy);
            Ability:Effect('Kamehameha_Beam', Caster, true)
        end},

        {1, 1.75, function(_, delta: number)
            Current_Hitbox_Size = Current_Hitbox_Size + (Vector3.zAxis * delta * 60 / 0.8)

			local Offset  = Vector3.zAxis * -(Current_Hitbox_Size.Z/2 - 0.5);
			Ability:CreateHitbox(Caster, Offset, Current_Hitbox_Size, function(Target: Types.Enemy)
				if HitTags[Target] then return end
				HitTags[Target] = true

				task.delay(Ability:FromData('Hit_Frequency'), function()
					HitTags[Target] = nil
				end)
				
 				Ability:Hit(Caster, Target, {NoHitStop = true})
			end)
        end},
    })
end

return Ability