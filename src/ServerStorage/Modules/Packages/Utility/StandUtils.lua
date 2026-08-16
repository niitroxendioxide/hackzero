local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local GameEnum = require(Shared.GameEnum)
local JotaroStandUtils = {}


function JotaroStandUtils:CheckAndSummon(Ability, Caster)
    local StandSummoned = Caster:GetEffect('StandSummoned')
    local Meter = Caster:GetMeter('Stand')

    if Meter >= 75 and not StandSummoned then
        local CreatedObject = Caster:AddEffect({
            Tag = 'StandSummoned',
        })

        if not CreatedObject then -- effect limit! never forget !
            return
        end

        Ability:Effect("JP3_Stand", {Caster, {State = true}}, true)

        Caster:SetMeterUpdateType('Stand', GameEnum.Meter_States.Empty, true, function()
            CreatedObject:Remove()
            Ability:Effect("JP3_Stand", {Caster, {State = false}}, true)
        end)
    end
end


return JotaroStandUtils