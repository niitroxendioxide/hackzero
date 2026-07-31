---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)

local ChargeOffset = CFrame.new(-0.089, -0.888, -1.118)
local RunOffset = CFrame.new(0.011, -1.456, 0.052)
local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local Args = {...}
    
    local NarutoVfx = Assets.Effects.Agents.Naruto
    local Model = typeof(Caster) == 'Instance' and Caster:IsA("Model") and Caster or Caster:GetModel()
    local RightArm = Model:FindFirstChild("Right Arm");
    
    if State == 'Charge' then
        ---
        local RasenganVFX = Effects:Create(NarutoVfx.Rasengan, 2.5);
        RasenganVFX:PivotTo(RightArm.CFrame * ChargeOffset);
        RasenganVFX:ScaleTo(0.001)

        Effects:Weld(RasenganVFX.PrimaryPart, RightArm)
        Effects:TweenModel(RasenganVFX, 1, 0.75, 'Quad')
        
        Cache[Caster] = {RasenganVFX}

        ---
        local RasenganCharge = Effects:Create(NarutoVfx.RasenganCharge, 3);
        RasenganCharge:PivotTo(RightArm.CFrame * ChargeOffset)
        Effects:Weld(RasenganCharge, RightArm);
        Effects:Tween(RasenganCharge.Charge.PointLight, {0.6, 'Sine', 'In'}, {Range = 6})
        
        local LineParticle = RasenganCharge.Charge.IntoBall :: ParticleEmitter
        LineParticle.Rate = 50
        Effects:Tween(LineParticle, { 0.65, 'Sine', 'In' }, {Rate = 0})

        task.delay(0.6, function()
            Effects:Tween(RasenganCharge.Charge.PointLight, {0.25, 'Quad'}, {Brightness = 0})
            Effects:Toggle(RasenganCharge, false)
        end)
    elseif State == 'Running' then
        local Time = Args[1]
        local Data = Cache[Caster]

        if Data then
            local OldRasengan = Data[1]
            OldRasengan:Destroy()
        end

        local NewRasengan = Effects:Create(NarutoVfx.Rasengan, 25);
        NewRasengan:PivotTo(RightArm.CFrame * RunOffset);

        Effects:Weld(NewRasengan.PrimaryPart, RightArm)

        Effects:Toggle(NewRasengan.Orb.Aura, true)
        Cache[Caster] = {NewRasengan}

        task.delay(Time, function()
            Cache[Caster] = nil

            NewRasengan:Destroy()
        end)
    elseif State == 'Release' then
        local Data = Cache[Caster]
        if not Data then
            return
        end

        local Rasengan = Data[1]

        if Rasengan then
            Rasengan:Destroy()
        end
    end
end