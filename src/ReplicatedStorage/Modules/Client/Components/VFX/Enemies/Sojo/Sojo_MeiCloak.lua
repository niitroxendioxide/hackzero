---
local ReplicatedStorage = game:GetService('ReplicatedStorage')



local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local LightningBolt = require(Client.Utility.Libraries.LightningBolt)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local Cache = {}

local function CreateBolt(CasterModel: Model, Ground: RaycastResult<BasePart> & {Color: Color3})
    local SojoEffects = Assets.Effects.Enemies.Sojo
    local Color = Color3.fromRGB(110, 112, 255)  --Color3.fromRGB(105, 165, 255)
    local Parent = Effects:GetParent(script.Name)
    
    local A1 = Instance.new('Attachment')
    A1.Name = 'LightningBoltAttachment'
    A1.Position = vector.create(Effects:Random(-0.5, 0.5), Effects:Random(-1, 1), Effects:Random(-0.5, 0.5))
    A1.WorldAxis = Effects:RandomV3()
    A1.Parent = CasterModel.PrimaryPart
    
    local Attachment = Instance.new('Attachment')
    local GroundUsed = true;
    
    if math.random(1, 3) == 1 then
        GroundUsed = false;
        local Parts = CasterModel:GetDescendants()
        for i = #Parts, 1, -1 do
            if Parts[i]:IsA('BasePart') then continue end
            table.remove(Parts, i)
        end

        local OtherPart = Parts[math.random(1, #Parts)]

        --Attachment.Position = Effects:RandomV3() * OtherPart.Size;
        Attachment.Parent = OtherPart
    else
        Attachment.WorldPosition = A1.WorldPosition
        Attachment.WorldAxis = Effects:RandomV3()
        Attachment.Parent = workspace.Terrain
        Effects:Tween(Attachment, {.1}, {WorldPosition = Ground.Position})
    end
    
    
    if GroundUsed then
        local Floor = Effects:Create(SojoEffects.FloorPart, 1.25)
        Floor:PivotTo(CFrame.lookAlong(Ground.Position, Ground.Normal) * CFrame.Angles(-math.pi/2, 0, 0))
        Floor.Parent = Parent

        task.delay(.1, function()
            Effects:RecolorSmoke(Ground, Floor:GetDescendants())

            Effects:Emit(Floor, true)
        end)

        Effects:CleanUp(Floor, 2.5)
    end
    
    local CurveSize = GroundUsed and 5.5 or 2.75
    local Radius = GroundUsed and {0.9, 2.25} or {0.33, 1.1}
    local RandomCurve = Effects:Random(-CurveSize, CurveSize)

    local NewBolt = LightningBolt.new(A1, Attachment, Effects:Random(8, 14))
    NewBolt.CurveSize0, NewBolt.CurveSize1 = RandomCurve, -RandomCurve
    NewBolt.PulseSpeed = Effects:Random(9, 24)
    NewBolt.PulseLength = Effects:Random(.75, 4)
    NewBolt.ContractFrom = 0
    NewBolt.MinRadius, NewBolt.MaxRadius = Radius[1], Radius[2]
    NewBolt.Thickness = Effects:Random(.15, .3)
    NewBolt.Frequency = Effects:Random(.2, .5)
    NewBolt.Color = Color
    NewBolt.Parent = Parent
    
    Effects:CleanUp(Attachment, 5)
    Effects:CleanUp(A1, 5)
end

---
return function(Caster: Types.ClientEnemy, Time: number?): ()
    if Cache[Caster] then
        return
    end

    Cache[Caster] = {
        Active = true,
    }

    ---
    local SojoEffects = Assets.Effects.Enemies.Sojo
    local AuraVfx = Effects:Create(SojoEffects.MeiCloakAura, Time + 2);
    AuraVfx.CFrame = Caster:GetModel():GetPivot()
    Effects:Weld(AuraVfx, Caster:GetModel().Torso)


    local Timer = os.clock()
    local UntilNextBolt = os.clock()

    while Cache[Caster].Active == true do
        if (Time < os.clock() - Timer) then
            Cache[Caster] = nil
            Effects:Toggle(AuraVfx, false)
            Effects:Tween(AuraVfx.Attachment.PointLight, { 0.25, 'Quad' }, { Brightness = 0 })

            break
        end

        if os.clock() - UntilNextBolt < 1/24 then
            task.wait()
            continue
        end

        UntilNextBolt = os.clock()

        local RandomPosition = Caster:GetPivot() * CFrame.new(Effects:Random(-5, 5), 2, Effects:Random(-5, 5))
        local Ground = Effects:CastMapRaycast(RandomPosition.Position, vector.create(0, -15))
        
        if Ground then
            CreateBolt(Caster:GetModel(), Ground)
        end

        task.wait()
    end

end