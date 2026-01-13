---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLibrary = require(Client.Libraries.Effects)
local LightningBolt = require(Client.Utility.Libraries.LightningBolt)

local Rotation = Effects.TableShortcut
local Range = Effects.TableShortcut
local Amount = Effects.TableShortcut

---
local Cache = {}
local CasterArms = {'Left Arm', 'Right Arm'};

return function(Caster: Types.Caster, State: string): ()
    local SorcererEffects = Assets.Effects.Enemies.Sorcerer
    local CasterModel = Caster:GetModel()
    local Parent = Effects:GetParent(script.Name)

    if State == 'Smash' then

        Cache[Caster].Active = false;
        for _, Object in Cache[Caster].Parts do
            Effects:Toggle(Object, false)
            Effects:CleanUp(Object, 1.5)
        end
        
        local Raycast = Effects:CastMapRaycast(Caster:GetPivot(), vector.create(0, -50))
        if Raycast then
            local ExplosionObject = Effects:Create(SorcererEffects.SorcererHitVfx, 5);
            ExplosionObject.CFrame = CFrame.lookAlong(Raycast.Position, Raycast.Normal) * CFrame.Angles(-math.pi, 0, 0)

            Effects:RecolorSmoke(Raycast, ExplosionObject:GetChildren())
            Effects:Emit(ExplosionObject, true)
            Effects:ShootRocks(Raycast, Amount{6, 8}, {30, 50}, Parent)
            Effects:CreateRocks(Raycast, vector.create(3.75, 1.75, 3.75), Amount{9, 11}, Range{8, 14}, Rotation{20, 45}, Parent)
        end

    elseif State == 'Jump' then

        EffectsLibrary:Play('Goku_RaiseVfx', Caster)

    elseif State == 'Charge' then

        if not Cache[Caster] then
            Cache[Caster] = {
                Parts = {},
                Active = true,
            }
        end

        Cache[Caster].Active = true;

        for _, CasterBodyPart in CasterArms do
            local BodyPart = CasterModel:FindFirstChild(CasterBodyPart)
            if not BodyPart then
                continue
            end

            local ChargeObject = Effects:Create(SorcererEffects.ElectricMageVfx, 5)
            ChargeObject.CFrame = BodyPart.CFrame * CFrame.new(0, -1, 0)
            Effects:Weld(ChargeObject, BodyPart)

            table.insert(Cache[Caster].Parts, ChargeObject)
        end

        
        local AuraVfx = Effects:Create(SorcererEffects.ElectricAuraVfx, 5);
        AuraVfx.CFrame = CasterModel:GetPivot()
        Effects:Weld(AuraVfx, CasterModel.Torso)
        table.insert(Cache[Caster].Parts, AuraVfx)


        local InitialExplosion = Effects:Create(SorcererEffects.ExplosionStartup, 5);
        InitialExplosion.CFrame = CasterModel:GetPivot()

        Effects:Emit(InitialExplosion, true)

        local UntilNextBolt = os.clock()
        while Cache[Caster].Active == true do
            if os.clock() - UntilNextBolt < 1/24 then
                task.wait()
                continue
            end

            UntilNextBolt = os.clock()
            local Color = Color3.fromRGB(105, 165, 255)

            local RandomPosition = Caster:GetPivot() * CFrame.new(Effects:Random(-7, 7), 2, Effects:Random(-7, 7))
            local Ground = Effects:CastMapRaycast(RandomPosition.Position, vector.create(0, -15))
            
            if Ground then
                local BasePart = CasterModel:FindFirstChild(CasterArms[math.random(1, #CasterArms)])
                local A1 = Instance.new('Attachment')
                A1.Name = 'LightningBoltAttachment'
                A1.Position = vector.create(Effects:Random(-0.5, 0.5), Effects:Random(-1, 1), Effects:Random(-0.5, 0.5))
                A1.WorldAxis = Effects:RandomV3()
                A1.Parent = BasePart
                
                local Attachment = Instance.new('Attachment')
                Attachment.WorldPosition = A1.WorldPosition
                Attachment.WorldAxis = Effects:RandomV3()
                Attachment.Parent = workspace.Terrain
                
                Effects:Tween(Attachment, {.1}, {WorldPosition = Ground.Position})
                
                local Floor = Effects:Create(SorcererEffects.FloorPart, 1.25)
                Floor:PivotTo(CFrame.lookAlong(Ground.Position, Ground.Normal) * CFrame.Angles(-math.pi/2, 0, 0))
                Floor.Parent = Parent
                
                --[[--temp code
                local Sound = ReplicatedStorage.Effects.Sounds.RHCP.Discharge["LightningFloor"..math.random(3)]:Clone()
                Sound.Parent = Floor
                Sound:Play()
                
                Effects:CleanUp(Sound, 1.2)]]
                
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

            task.wait()
        end
        

    end

end