---
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared

local AgentTypes = require(Shared.Types.Agents)


---
local Controller = {
    __Cache = {},
}

function Controller:AddUltimateCharge(Caster: AgentTypes.ServerAgentClass, Amount: number, Maximum: number)
    if (Controller.__Cache[Caster] == nil) then
        Controller.__Cache[Caster] = 0
    end

    --
    Caster:UpdateMeter('AkaCharge', Amount)
    Controller.__Cache[Caster] = math.clamp(Controller.__Cache[Caster] + Amount, 0, Maximum)
    
end



function Controller:UseUltimateCharge(Caster: AgentTypes.ServerAgentClass): number
    local StoredAmount = Controller.__Cache[Caster]
    Caster:UpdateMeter('AkaCharge', -StoredAmount)

    Controller.__Cache[Caster] = 0

    return StoredAmount
end

return Controller