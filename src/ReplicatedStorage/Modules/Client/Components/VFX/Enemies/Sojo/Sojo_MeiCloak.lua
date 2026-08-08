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
    local SorcererEffects = Assets.Effects.Enemies.Sorcerer
    local Color = Color3.fromRGB(105, 165, 255)
    local Parent = Effects:GetParent(script.Name)
    
    local A1 = Instance.new('Attachment')
    A1.Name = 'LightningBoltAttachment'
    A1.Position = vector.create(Effects:Random(-0.5, 0.5), Effects:Random(-1, 1), Effects:Random(-0.5, 0.5))
    A1.WorldAxis = Effects:RandomV3()
    A1.Parent = CasterModel.PrimaryPart
    
    local Attachment = Instance.new('Attachment')
    Attachment.WorldPosition = A1.WorldPosition
    Attachment.WorldAxis = Effects:RandomV3()
    Attachment.Parent = workspace.Terrain
    
    Effects:Tween(Attachment, {.1}, {WorldPosition = Ground.Position})
    
    local Floor = Effects:Create(SorcererEffects.FloorPart, 1.25)
    Floor:PivotTo(CFrame.lookAlong(Ground.Position, Ground.Normal) * CFrame.Angles(-math.pi/2, 0, 0))
    Floor.Parent = Parent

    task.delay(.1, function()
        Effects:RecolorSmoke(Ground, Floor:GetDescendants())

        Effects:Emit(Floor, true)
    end)

    Effects:CleanUp(Floor, 2.5)
    
    local RandomCurve = Effects:Random(-5, 5)

    local NewBolt = LightningBolt.new(A1, Attachment, Effects:Random(8, 14))
    NewBolt.CurveSize0, NewBolt.CurveSize1 = RandomCurve, -RandomCurve
    NewBolt.PulseSpeed = Effects:Random(9, 24)
    NewBolt.PulseLength = Effects:Random(.75, 4)
    NewBolt.ContractFrom = 0
    NewBolt.MinRadius, NewBolt.MaxRadius = .9, 2.25
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

    local Timer = os.clock()
    local UntilNextBolt = os.clock()

    while Cache[Caster].Active == true do
        if (Time < os.clock() - Timer) then
            Cache[Caster] = nil

            break
        end

        if os.clock() - UntilNextBolt < 1/24 then
            task.wait()
            continue
        end

        UntilNextBolt = os.clock()

        local RandomPosition = Caster:GetPivot() * CFrame.new(Effects:Random(-7, 7), 2, Effects:Random(-7, 7))
        local Ground = Effects:CastMapRaycast(RandomPosition.Position, vector.create(0, -15))
        
        if Ground then
            CreateBolt(Caster:GetModel(), Ground)
        end

        task.wait()
    end

end