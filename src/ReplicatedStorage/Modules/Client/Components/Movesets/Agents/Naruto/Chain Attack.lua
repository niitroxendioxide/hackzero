--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass)
    
    local AttackStateTime = Ability:FromData("Attack_State_Time")
    local Offset = Ability:FromData("Offset")
    local Size = Ability:FromData("Size")

    local HitCount = Ability:FromData("HitCount")
    local HitFrequency = Ability:FromData("HitFrequency")
    local HitList = {}
    local Released = false
    local function Release()
        if Released then
            return;
        end

        Released = true

        Caster:Walk(0.001, 1, true)
        Ability:PlayAnimation(Caster, 'Naruto.Abilities.Special.RasenganRelease', {
            Active_Time = 0.5
        })

        Ability:Effect("Naruto_Rasengan", Caster, "Release")
    end

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime)
            Ability:Effect("Naruto_Rasengan", Caster, "Running", 0.5)
            Ability:PlayAnimation(Caster, 'Naruto.Abilities.ChainAttack.User', {
                Active_Time = 0.5
            })
        end},
        
        {0.167, function()
            Caster:Walk(0.25, 1, true)
        end},

        {0.167, 0.4, function()
            if Released then
                return
            end

			Ability:CreateHitbox(Caster, Offset, Size, function(Enemy)
                if HitList[Enemy] then
                    return
                end

                Release()
                HitList[Enemy] = true
                Ability:Effect("Naruto_RasenganHit", Enemy, HitCount, HitFrequency)
                Ability:Effect("GroundRocksTrail", Enemy, (HitCount * HitFrequency) + 0.25, false)

                for i = 1, HitCount do 
                    Ability:Hit(Caster, Enemy, {EffectData = {HueShift = 170}})

                    task.wait(HitFrequency)
                end
			end)
		end},
    })
end

return Ability