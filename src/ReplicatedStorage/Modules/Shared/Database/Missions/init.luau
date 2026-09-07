local Missions = {
    __Cached = {}
}

export type Mission = {
    Stage_Act: string,
    Description: string,
    Display_Name: string,
    Recommended_Level: number,
    Difficulty: string?,

    --- Hidden from the lobby listing, used for generated/test missions.
    Invisible: boolean?,

    --[[
        Mission kind, e.g. 'Recover'. Resolves the world handler at
        `Components/Missions/<Kind>`. Optional here: a database entry already describes
        itself, this is for entries that still want a handler to dress the run.
    ]]
    Kind: string?,

    --[[
        Build this mission's map with the dungeon generator rather than unpacking the
        stage's static asset. Leaving it nil defers to the stage act's `AutoGenerate`.
    ]]
    Procedural: boolean?,

    --[[
        Seed this mission is pinned to. Nil lets the run decide, which is what a
        procedurally generated mission wants, it carries its seed on the run instead.
        Accepts a number or an authored string.
    ]]
    Seed: (number | string)?,

    --[[
        Generation parameter overrides layered on top of the stage act's defaults.
        See `Types.ProceduralMissionData`: Rooms / Extent / Source / Infinite / Trail.
    ]]
    Generation: {[string]: any}?,

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
