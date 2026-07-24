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
    local Model = Caster:GetModel()
    local RightArm = Model:FindFirstChild("Right Arm");
    
    if State == 'Charge' then
        local RasenganVFX = Effects:Create(NarutoVfx.Rasengan, 5);
        RasenganVFX:PivotTo(RightArm.CFrame * ChargeOffset);
        
        Effects:Weld(RasenganVFX.PrimaryPart, RightArm);

        Cache[Caster] = RasenganVFX
    elseif State == 'Running' then
        local RasenganBall = Cache[Caster]

        if RasenganBall then
            RasenganBall:Destroy()
        end

        ---
        local Time = Args[1]

        local RasenganVFX = Effects:Create(NarutoVfx.Rasengan, Time + 2);
        RasenganVFX:PivotTo(RightArm.CFrame * RunOffset);
        
        local Weld = Effects:Weld(RasenganVFX.PrimaryPart, RightArm);
        Weld.Name = 'rasenganweld'

        Cache[Caster] = RasenganVFX
        Effects:Toggle(RasenganVFX.Orb.Aura, true)

        task.delay(Time, function()
            Cache[Caster] = nil

            Effects:Toggle(RasenganVFX, false)
            Effects:Tween(RasenganVFX.Orb, {0.2}, {Transparency = 1})
        end)
    end
end