


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Library = require(Client.Libraries.Effects)


---
local Rng = Random.new()
local MeshTweens = {
    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.35, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .275, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.75, 2.45) })
        Effects:Tween(Innermesh, { .35, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2.25, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,

    Shock = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.375, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .35, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.75, 2.75) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(4, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0
    end,
}

local function ShootDragon(BaseCFrame)
    local SasukeVFX = Assets.Sasuke
    local FireballShootVFX = Effects:Create(SasukeVFX.ShootFireball, 1)
    FireballShootVFX:PivotTo(BaseCFrame)
    Effects:Emit(FireballShootVFX)
    
    local FireballVFX = Effects:Create(SasukeVFX.Dragon, 4)
    FireballVFX:PivotTo(BaseCFrame)
    FireballVFX:ScaleTo(0.001)
    local Anim = Animation:GetAnim('Characters.Sasuke.Abilities.Ultimate.DragonFire')
    Animation:Play(FireballVFX, Anim, 0, 1, 1.25)

    Effects:TweenModel(FireballVFX, 5.859, 0.45, 'Back')

    local Cleaned = false;
    local function CleanUp()
        if Cleaned then
            return;
        end

        Cleaned = true;

        for _, Part in FireballVFX:GetChildren() do
            if Part:IsA('BasePart') then
                Effects:Tween(Part, {.1}, {Transparency = 1})
            end
        end

        Library:Play("Sasuke_FireExplosion", FireballVFX:GetPivot())
        Effects:Toggle(FireballVFX, false)
        Effects:Tween(FireballVFX.PrimaryPart, { 0.1, 'Quad' }, {Transparency = 1})
    end

    local Hits = {}
    local Lifetime = 1.5
    local Object; Object = Effects:MoveProjectile(FireballVFX, vector.create(12, 12, 4), 75, Lifetime, function(Target): boolean
        Object:SetSpeed(12);
        
        if Hits[Target] then
            return
        end

        Hits[Target] = true
        Target:Hit({});

        task.delay(0.12, function()
            Hits[Target] = false
        end)
    end)

    task.delay(Lifetime, CleanUp)
    task.spawn(function()
        local Last = os.clock()
        while not Cleaned do
            local _ = task.wait();

            if os.clock() - Last < 1 / 14 then
                continue
            end

            Last = os.clock()
            
            local Hit_Effect = Effects:Create(Assets.Goku.BasicAttack.DashVFX, 3)
            Hit_Effect:PivotTo(FireballVFX:GetPivot() * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 0, Rng:NextNumber(-math.pi, math.pi)))

            Effects:ForModelParts(Hit_Effect, MeshTweens)
        end
    end)
end

---
return function(
    Caster: Types.Caster
): ()
    --

    local Offset = CFrame.new(0, 0, -3.5)

    task.delay(0.7, ShootDragon, Caster:GetPivot() * CFrame.Angles(0, math.rad(38), 0) * Offset)
    task.delay(1.05, ShootDragon, Caster:GetPivot() * Offset)
    task.delay(1.3, ShootDragon, Caster:GetPivot() * CFrame.Angles(0, math.rad(-38), 0) * Offset)
end