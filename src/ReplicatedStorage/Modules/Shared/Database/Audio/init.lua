--[[
    @niitroxendioxide 2025-10

    Audio database for the game.
]]

export type AudioInformation = {
    Id: number | { number },
    Volume: number?,
    Category: string?,
    Priority: string?,
    Loop: boolean?,
}

local AudioDatabase = {}

AudioDatabase.General = {
	Music = {
        Maps = {
            Training = {
                Id = 1841998846,
            }
        },

        Stages = {

        },
    },

    Effects = {

    }
}

function AddDirectory(p_Directory: Instance | ModuleScript, p_CurrentDirectory: {any}?)
    local CurrentDir = p_CurrentDirectory or AudioDatabase.General;

    if p_Directory:IsA("ModuleScript") then
        CurrentDir[p_Directory.Name] = require(p_Directory);
    else
        for _, Child in p_Directory:GetChildren() do
            if Child:IsA("ModuleScript") then
                CurrentDir[Child.Name] = require(Child);
            else
                if not CurrentDir[Child.Name] then
                    CurrentDir[Child.Name] = {};
                end

                AddDirectory(Child, CurrentDir[Child.Name]);
            end
        end
    end
end

function AudioDatabase:Init()

    for _, Child in script:GetChildren() do
        if Child:IsA("Folder") and not AudioDatabase.General[Child.Name] then
            AudioDatabase.General[Child.Name] = {};
            AddDirectory(Child, AudioDatabase.General[Child.Name]);
        else
            AddDirectory(Child);
        end

    end

    print(AudioDatabase.General)

end

function AudioDatabase:FromString(p_AudioDir: string): AudioInformation? 
    local Split = string.split(p_AudioDir, '/')
    local Current = AudioDatabase.General;
    
    for i = 1, #Split do
        local var = Split[i]
        if Current[var] then
            Current = Current[var]
        end

        return nil;
    end

    if typeof(Current) == 'table' and Current.Id then
        return table.clone(Current);
    end
    
    return nil;
end

return AudioDatabase
