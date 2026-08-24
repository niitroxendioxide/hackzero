---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)

local Offset = CFrame.new(-0.013, -0.793, 0.033)
local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    local _Args = {...}
    
    local KakashiVfx = Assets.Effects.Agents.Kakashi
    local Model = typeof(Caster) == 'Instance' and Caster:IsA("Model") and Caster or Caster:GetModel()
    local RightArm = Model:FindFirstChild("Right Arm");
    
    if State == 'Charge' then
        ---
        local At = CFrame.lookAlong((RightArm.CFrame * Offset).Position, Caster:GetPivot().LookVector)
        local RaikiriVFX = Effects:Create(KakashiVfx.Raikiri, nil, false);
        RaikiriVFX:PivotTo(At);
        RaikiriVFX.Parent = workspace

        Effects:Weld(RaikiriVFX.PrimaryPart, RightArm)
        --Effects:TweenModel(RaikiriVFX, 1, 0.15, 'Quad')
        
        Cache[Caster] = {RaikiriVFX}
    elseif State == 'Delete' then
        local Data = Cache[Caster]
        if not Data then
            return
        end

        local Raikiri = Data[1]

        if Raikiri then
            Effects:Toggle(Raikiri, false)
            Effects:CleanUp(Raikiri, .5)
        end
    end
end