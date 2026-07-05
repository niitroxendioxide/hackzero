local Missions = {
    __Cached = {}
}

export type Mission = {
    Stage_Act: string,
    Description: string,
    Display_Name: string,
    Recommended_Level: number,

    Destructibles: {},
    Triggers: {},
    Completion: {},
    Mission_Data: {},
}

function Missions:Init()
    
    for _, MissionModule in script:GetChildren() do
        if MissionModule:IsA('ModuleScript') then
            local MissionsInModule = require(MissionModule)
            
            if typeof(MissionsInModule) ~= 'table' then continue end
            for MissionId, Data in MissionsInModule do
                Missions.__Cached[MissionId] = Data
            end
        end
    end

end

function Missions:Get(Id: string): Mission
    return Missions.__Cached[Id]
end

function Missions:GetAll(Invisible: boolean?): {[string]: Mission}
    if Invisible then
        return Missions.__Cached
    end

    local List = {}
    for Key, Data in Missions.__Cached do
        if Data.Invisible == true then
            continue
        end

        List[Key] = Data
    end

    return List
end

return Missions
