--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local World = require(ReplicatedStorage.Modules.Shared.World)
local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local GrabService = require(Services.Combat.GrabService)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent, _, _, Context): ()

	local AttackStateTime = Ability:FromData("Attack_State_Time")
    local Offset = Ability:FromData("Offset")
    local Size = Ability:FromData("Size")

    local HitList = {}
    local Released = false
	local HitData = Ability:FromData("Hit")
	local FinalData = Ability:FromData("Final")
	local HitCount = Ability:FromData("HitCount")
	local HitFrequency = Ability:FromData("HitFrequency")

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime)
        end},
        
        {0.167, function()
            Caster:Walk(0.25, 1.45, true)
        end},

        {0.167, 0.4, function()
            if Released then
                return
            end

			Ability:CreateHitbox(Caster, Offset, Size, function(Enemy)
                if HitList[Enemy] then
                    return
                end

				if not Released then
        			Caster:Walk(0.001, 1, true)
				end
				
                Released = true
				HitList[Enemy] = true

				for i = 1, HitCount do
					Ability:Hit(Caster, Enemy, i == HitCount and FinalData or HitData)

					task.wait(HitFrequency)
				end
			end)
		end},
    })
end

return Ability
