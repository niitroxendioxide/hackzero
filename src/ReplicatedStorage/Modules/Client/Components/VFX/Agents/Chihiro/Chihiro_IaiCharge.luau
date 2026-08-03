---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

--- Saved stuff

---
return function(
    Caster: Types.Caster
): ()
    local ChihiroAssets = Assets.Chihiro
    local CasterModel = Caster:GetModel()

    local KatanaModel = CasterModel:FindFirstChild("Katana")
    if not KatanaModel then
        return;
    end

    ---
    local DashEffect = Effects:Create(ChihiroAssets.IaiCharge, 3) 
    DashEffect:PivotTo(Caster:GetPivot() * CFrame.new(0.505, -0.419, 1.216))

    task.delay(0.2, function()
        local SheatheEffect = Effects:Create(ChihiroAssets.SheatheEffect, 3, KatanaModel.Sheathe) 
        Effects:Emit(SheatheEffect, true)
        
        task.wait(0.2)
        Effects:Toggle(DashEffect, false)
    end)
end