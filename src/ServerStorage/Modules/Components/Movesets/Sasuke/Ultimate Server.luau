--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Table = require(ReplicatedStorage.Modules.Shared.Utility.Table)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass)
    local CasterLevel = Caster:GetSkillLevel(Ability.__Name)

    local AttackStateTime = Ability:FromData("Attack_State_Time")
    local ExplosionData = Ability:FromData("Explosion", nil, CasterLevel)
    local ExplosionRadius = Ability:FromData("ExplosionRadius")
    local ExplosionSize = vector.create(ExplosionRadius, ExplosionRadius, ExplosionRadius)
    
    local BaseHitData = Ability:FromData("Hit", nil, CasterLevel)

    local Hits = {}
    local Left, Right = CFrame.Angles(0, math.rad(38), 0), CFrame.Angles(0, math.rad(-38), 0)
    local Projectiles = {}
    local Lifetime = 1.5

    local function FireballHit(Enemy, Id, Object)
        if Hits[Enemy] == true then
            return
        end

        Hits[Enemy] = true;
        task.delay(Ability:FromData("Hit_Frequency"), function()
            Hits[Enemy] = false;
        end)

        local Direction = Enemy:GetPivot():VectorToObjectSpace(Object:GetPivot().LookVector)
        BaseHitData.Knockback = {
            Direction,
            12,
            .1
        }

        Ability:Hit(Caster, Enemy, BaseHitData)
    end

    local function ExplosionHit(Enemy, ProjectileId)
        local ExplosionOrigin = (Projectiles[ProjectileId]:GetPivot().Position - Enemy:GetPivot().Position).Unit
        local Direction = Enemy:GetPivot():VectorToObjectSpace(-ExplosionOrigin)
        ExplosionData.Knockback = {
            Direction,
            45,
            .3
        }

        Ability:Hit(Caster, Enemy, ExplosionData)
    end

    
	Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', AttackStateTime, true)
            Ability:Effect("Sasuke_DragonFire", {Caster}, true)
        end},

        {0.7, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * Left * CFrame.new(0, 0, -1), vector.create(12, 12, 24), 75, Lifetime, function(Target)
                Object:SetSpeed(12)
                FireballHit(Target, 1, Object)
            end)

            Projectiles[1] = Object
        end},

        {1.05, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -1), vector.create(12, 12, 24), 75, Lifetime, function(Target)
                Object:SetSpeed(12)
                FireballHit(Target, 2, Object)
            end)

            Projectiles[2] = Object
        end},

        {1.3, function(Sequence)
            local Object; Object = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * Right * CFrame.new(0, 0, -1), vector.create(12, 12, 24), 75, Lifetime, function(Target)
                Object:SetSpeed(12)
                FireballHit(Target, 3, Object)
            end)

            Projectiles[3] = Object
        end},

        {0.7 + Lifetime, function()
            local Projectile = Caster:GetPivot():ToObjectSpace(Projectiles[1]:GetPivot())
            Ability:CreateHitbox(Caster, Projectile.Position, ExplosionSize, function(Enemy)
                ExplosionHit(Enemy, 1)
            end)
        end},

        {1.05 + Lifetime, function()
            local Projectile = Caster:GetPivot():ToObjectSpace(Projectiles[2]:GetPivot())
            Ability:CreateHitbox(Caster, Projectile.Position, ExplosionSize, function(Enemy)
                ExplosionHit(Enemy, 2)
            end)
        end},

        {1.3 + Lifetime, function()
            local Projectile = Caster:GetPivot():ToObjectSpace(Projectiles[3]:GetPivot())
            Ability:CreateHitbox(Caster, Projectile.Position, ExplosionSize, function(Enemy)
                ExplosionHit(Enemy, 3)
            end)
        end},
    })
end

return Ability
