


export type TriggerData = {

}


----
local Cache = {
    Triggers = {},
}

function Cache:GetTriggerData(Id: string)
    return Cache.Triggers[Id];
end

function Cache:SaveTriggerData(Id: string, Data: {})
    Cache.Triggers[Id] = Data;
end

return Cache