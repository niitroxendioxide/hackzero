local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

---
local EffectSerdes = {
    IdByteSize = 1,
    EffectCount = 0,
    EffectIds = {},
    EffectNames = {},
}

function EffectSerdes:Init()

    local LocalCache = {}
    for _, EffectModule in Client.Components.VFX:GetDescendants() do
        if not EffectModule:IsA('ModuleScript') then
            continue 
        end

        table.insert(LocalCache, EffectModule.Name)
        EffectSerdes.EffectCount += 1;
    end

    table.sort(LocalCache, function(a0, a1): boolean  
        return a0 < a1
    end)

    for Id, Name in LocalCache do
        EffectSerdes.EffectIds[Id] = Name;
        EffectSerdes.EffectNames[Name] = Id;
    end

    for ByteCount = 1, 4 do
        local IsEnough = math.pow(2, 8 * ByteCount) - 1;
        if IsEnough > EffectSerdes.EffectCount then
            EffectSerdes.IdByteSize = ByteCount

            break
        end
    end
end

function EffectSerdes:ForName(Name: string): number
    return EffectSerdes.EffectNames[Name] :: number
end

function EffectSerdes:FromId(Id: number): string
    return EffectSerdes.EffectIds[Id] :: string
end

return EffectSerdes