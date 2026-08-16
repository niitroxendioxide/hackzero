---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Characters = require(Client.Libraries.Characters)

---
local Cache = {}

return function(Caster: Types.Caster, State: string): ()
    local FireballFX = Assets.Effects.Enemies.Sorcerer.Fireball
    local CasterModel = Caster:GetModel()
    --local Parent = Effects:GetParent(script.Name)

    if State == 'Shoot' then

        for _, Part in Cache[Caster].Parts do
            Effects:Toggle(Part, false, nil, true)
            Effects:CleanUp(Part, 1.5)
        end

        ---
        local FireballVfx = Effects:Create(FireballFX.Blast, 2)
        FireballVfx:PivotTo(Caster:GetModel():GetPivot())
        Effects:Toggle(FireballVfx, true)

        FireballVfx:ScaleTo(0.001)
        Effects:TweenModel(FireballVfx, 1, 0.1)

        local Cleaned = false;
        local function CleanUp()
            if Cleaned then
                return;
            end

            Cleaned = true;

            Effects:Toggle(FireballVfx, false)
            Effects:Tween(FireballVfx.Ball, {.25}, {Size = vector.zero})

            for _, Beam in FireballVfx:GetDescendants() do
                if Beam:IsA('Beam') then
                    Effects:Tween(Beam, {0.15}, {Width0 = 0, Width1 = 0})
                end
            end
        end

        local CastVfx = Effects:Create(FireballFX.ShootBlast, 1)
        CastVfx:PivotTo(Caster:GetPivot() * CFrame.new(0, 0, -2.5))
        Effects:Emit(CastVfx)

        ---
        local OverlapParams = OverlapParams.new()
        OverlapParams.FilterDescendantsInstances = Characters:GetAllHitboxes()
        OverlapParams.FilterType = Enum.RaycastFilterType.Include

        task.delay(1, CleanUp)

        Effects:MoveProjectile(FireballVfx, vector.create(5, 5), 135, 1, function(Target): boolean 
            if not Target:CanBeHit() then
                return;
            end

            CleanUp()

            local HitVFX = Effects:Create(FireballFX.BlastHit, 1)
            HitVFX:PivotTo(FireballVfx:GetPivot())
            Effects:Emit(HitVFX)

            return true
        end, OverlapParams)

    elseif State == 'Charge' then

        if not Cache[Caster] then
            Cache[Caster] = {
                Parts = {},
                Active = true,
            }
        end

        Cache[Caster].Active = true;


        ---
        local MainAura = Effects:Create(FireballFX.ChargeAura, 2);
        MainAura.CFrame = CasterModel:GetPivot();

        local RightArm = CasterModel['Right Arm']
        local ArmChargeAura = Effects:Create(FireballFX.FireSorcererVfx, 2);
        ArmChargeAura:PivotTo(RightArm.CFrame * CFrame.new(0, -1, 0));
        Effects:Weld(ArmChargeAura, RightArm);

        
        table.insert(Cache[Caster].Parts, MainAura)
        table.insert(Cache[Caster].Parts, ArmChargeAura)
    end

end 