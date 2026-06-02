--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)
local Agents = require(ServerStorage.Modules.Libraries.Agents)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)

    local Ult_Length = Ability:FromData("Ult_Length")
	local Base_Attack_Time = Ability:FromData('Attack_State_Time')

    local HitFrequency = Ability:FromData("Hit_Frequency")
    local Last_Hit = os.clock()
    local RNG = Random.new(Last_Hit)
    local HitData = Ability:FromData("Hit_Data")
    local CollatHitData = Ability:FromData("Collat_Hit")
    local LastTarget = nil;
    local CasterPlayer = Caster.__Player_Assigned

	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', Base_Attack_Time + Ult_Length - 1.3, true)
        end},

        {1, 6, function()
            if (os.clock() - Last_Hit) < HitFrequency then
                return
            end

            Last_Hit = os.clock()

            local Centre = Caster:GetPivot()
            if CasterPlayer then
                Centre = Agents:GetCurrentActive(CasterPlayer:GetAttribute("ReplicationId") :: number):GetPivot()
            end

            local RandomSpot = CFrame.new(RNG:NextNumber(-50, 50), 18, RNG:NextNumber(-50, 50))
            local WorldSpot = (Centre * RandomSpot).Position
            
            local AllEnemies = Enemies:GetAll()
            local Closest, Target = math.huge, nil
            for _, Enemy in AllEnemies do
                local Distance = ((Enemy:GetPivot().Position - WorldSpot) * Vector3.new(1, 0, 1)).Magnitude;
                if (Distance < Closest) and ((LastTarget ~= nil and LastTarget ~= Target) or LastTarget == nil) then
                    Closest = Distance
                    Target = Enemy
                end
            end

            local ChooseAgain = math.random(100) < 65 
            if Target == nil and LastTarget ~= nil and ChooseAgain then 
                Target = LastTarget
            end
            
            if Target ~= nil then
                local ChanceToHit = (LastTarget == Target) and 25 or 70
                local Chance = math.random(100)

                if Chance < ChanceToHit then
                    WorldSpot = Target:GetPivot().Position
                    Ability:Hit(Caster, Target, HitData)
                    Ability:Effect("Hit", {Target:GetPivot()}, true)
                else
                    local Offset = vector.create(RNG:NextNumber(-1, 1), 0, RNG:NextNumber(-1, 1)) * RNG:NextNumber(10, 17)
                    WorldSpot = Target:GetPivot().Position + Offset
                end
            end

            LastTarget = Target

            Ability:Effect("Miku_AirStrike", {WorldSpot, 0.15}, true)
            
            local toLocalCF = Caster:GetPivot():ToObjectSpace(CFrame.new(WorldSpot))
            Ability:CreateHitbox(Caster, toLocalCF.Position, vector.create(9, 9, 9), function(Enemy)
                Ability:Hit(Caster, Target, CollatHitData)
                Ability:Effect("Hit", {Target:GetPivot()}, true)
            end)
        end}
    })
end

return Ability
