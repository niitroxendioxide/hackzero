


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff
local Rng = Random.new()

local MeshTweens = {
    Wind = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.2, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .15, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.1, 1.3) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2.25, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0.45
    end,

    Rings = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.15, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .3, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.3, 1.6) })
        Effects:Tween(Innermesh, { .3, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(2, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.09, 0.225), 0, 0) })

        Innermesh.Mesh.Scale *= 0.15
    end,

    Shock = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.1, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .2, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * Rng:NextNumber(1.1, 1.3) })
        Effects:Tween(Innermesh, { .15, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-2, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0.45
    end,

    Fire = function(Innermesh)
        Effects:Tween(Innermesh.Decal, {.2, 'Sine'}, {Transparency = 1})
        Effects:Tween(Innermesh.Mesh, { .3, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * vector.create(Rng:NextNumber(1.1, 1.3), Rng:NextNumber(1.1, 1.3), Rng:NextNumber(1.3, 1.6)) })
        Effects:Tween(Innermesh, { .33, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(-1, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0.45
    end,

    Impact = function(Innermesh)
        Effects:Tween(Innermesh.Mesh, { .2, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * vector.create(Rng:NextNumber(1.1, 1.3), 0, 0) })
        Effects:Tween(Innermesh, { .33, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(2, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })

        Innermesh.Mesh.Scale *= 0.45
    end,

    Fast = function(Innermesh)
        Innermesh.CFrame *= CFrame.Angles(Rng:NextNumber(-math.pi, math.pi), 0, 0)
        Effects:Tween(Innermesh.Mesh, { .3, 'Cubic' }, { Scale = Innermesh.Mesh.Scale * vector.create(Rng:NextNumber(2, 2.35), Rng:NextNumber(1.2, 1.35), Rng:NextNumber(1.2, 1.35)) })
        Effects:Tween(Innermesh, { .275, 'Quart' }, { CFrame = Innermesh.CFrame * CFrame.new(2, 0, 0) * CFrame.Angles(-math.pi * Rng:NextNumber(0.03, 0.15), 0, 0) })
        task.delay(0.1, function()
            Effects:Tween(Innermesh.Decal, { 0.1 }, {Transparency = 1})
        end)

        Innermesh.Mesh.Scale *= 0.3
    end,
}

function CreateTrail(Caster, Angle: number, Time: number)
    local Current = Angle or 0;
    local Z = -3;
    local Radius = 5;
    local TrailObj = Effects:Create(Assets.Goku.GodFist.Trail, 2)
    TrailObj.CFrame = Caster:GetModel():GetPivot() * CFrame.new(math.cos(Current) * Radius, math.sin(Current) * Radius, Z)

    local Connection do
        local Since = os.clock()
        Connection = RunService.Heartbeat:Connect(function(Delta: number)  
            if (os.clock() - Since) > Time then
                Connection:Disconnect()
                return
            end

            local Period = (os.clock() - Since) / Time
            local AltAlph = TweenService:GetValue(Period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

            Current += Delta * math.tau
            Radius = math.lerp(5, 0, AltAlph)

            TrailObj.CFrame = Caster:GetModel():GetPivot() * CFrame.new(math.cos(Current) * Radius, math.sin(Current) * Radius, Z)
        end)
    end
end

local Cache = {}
local Threads = {}
---
return function(
    Caster: Types.Caster,
    State: string
): ()
    ---
    if State == 'Attack' then

        if Cache[Caster] then
            Cache[Caster]()
        end
        
        if Threads[Caster] then
            task.cancel(Threads[Caster])
        end

        local DashEffect = Effects:Create(Assets.Goku.GodFist.DashTrail, 2)
        DashEffect.Anchored = false
        DashEffect:PivotTo(Caster:GetModel():GetPivot())
        Effects:Weld(DashEffect, Caster:GetModel().PrimaryPart)

        local BeamsDash = Effects:Create(Assets.Goku.GodFist.Dash, 2)
        BeamsDash:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0, -3))

        ---
        local GroundDashEffect = Effects:Create(Assets.Goku.GodFist.GroundDash, 2)
        GroundDashEffect.Anchored = false
        GroundDashEffect:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, -2.9, 0))
        Effects:Weld(DashEffect, Caster:GetModel().PrimaryPart)
        Effects:RecolorToGroundColor(Caster:GetModel():GetPivot().Position, GroundDashEffect:GetChildren())

        for _, Obj in BeamsDash:GetDescendants() do
            if Obj:IsA('Beam') then
                Effects:Tween(Obj, { Rng:NextNumber(0.2, 0.25), 'Quad' }, {Width0 = 0, Width1 = 0})
            elseif Obj:IsA('Attachment') then
                local Z = Obj.Position.Z
                Obj.Position = vector.create(1, 1, 0)
                Effects:Tween(Obj, { Rng:NextNumber(0.1, 0.3), 'Sine' }, {Position = vector.create(0, 0, Z)})                
            end
        end

        for i = 1, 4 do
            CreateTrail(Caster, (math.pi / 2) * (i - 1), 0.4)
        end

        local Active_Time = 0

        while Active_Time < 0.25 do
            Active_Time += Effects:Wait(1 / 14)

            local Hit_Effect = Effects:Create(Assets.Goku.GodFist.Mesh, 3)
            Hit_Effect:PivotTo(Caster:GetModel():GetPivot() * CFrame.new(0, 0.33, 0))

            Effects:ForModelParts(Hit_Effect, MeshTweens)
        end

        Effects:Toggle(DashEffect, false)

    elseif State == 'Charge' then

        if Threads[Caster] then
            task.cancel(Threads[Caster])
        end

        if Cache[Caster] then
            Cache[Caster]()
        end

        local RightArm = Caster:GetModel()['Right Arm']
        local ArmChargeVfx = Effects:Create(Assets.Goku.GodFist.Charge, 2)
        ArmChargeVfx.Anchored = false
        ArmChargeVfx:PivotTo(RightArm.CFrame * CFrame.new(0, -0.85, 0))
        ArmChargeVfx.Transparency = 0.9
        Effects:Weld(ArmChargeVfx, RightArm)

        for _, Aura in Assets.Goku.GodFist.ArmAura:GetChildren() do
            local Clone = Aura:Clone()
            Clone.Name = 'GokuGodFistAura'
            Clone.Parent = RightArm
        end

        local ArmCloneModel = Instance.new('Model')
        local ClonedArm = RightArm:Clone()
        ClonedArm:ClearAllChildren()
        ClonedArm.Size *= 1.05
        ClonedArm.Parent = ArmCloneModel
        Effects:Weld(ClonedArm, RightArm)
        ArmCloneModel.Parent = Effects:GetParent(script.Name)

        local Highlight = Instance.new('Highlight')
        Highlight.FillColor = Color3.fromRGB(255, 155, 33)
        Highlight.OutlineColor = Color3.fromRGB(255, 157, 0)
        Highlight.FillTransparency = 0.7
        Highlight.OutlineTransparency = 0.4
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.Parent = ArmCloneModel

        Cache[Caster] = function()
            Effects:Toggle(ArmChargeVfx, false)
            for _, AuraVFX in RightArm:GetChildren() do
                if AuraVFX.Name == 'GokuGodFistAura' then
                    AuraVFX.Enabled = false
                    AuraVFX.Name = 'dipptiy'
                    Effects:CleanUp(AuraVFX, 1)
                end
            end

            ArmCloneModel:Destroy()
        end

        Threads[Caster] = task.delay(1, Cache[Caster])

        --
        for _, Part in Caster:GetModel():FindFirstChild('Parts')['Right Arm']:GetChildren() do
            if Part:IsA('BasePart') then
                local ClonedObject = Part:Clone()
                ClonedObject.Size *= 1.05
                ClonedObject.Parent = ArmCloneModel
                
                Effects:Weld(ClonedObject, ClonedArm)
            end
        end
    end
end