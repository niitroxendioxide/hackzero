local RunService = game:GetService("RunService")
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

local AudioDatabase = {
    __Cache = {},
}

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
        Dodge = { 
            Id = { 108928552267639, 101379165800189, 138149044086182 } 
        },
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
    if RunService:IsServer() then
        return
    end

    for _, Child in script:GetChildren() do
        if Child:IsA("Folder") then
            if not AudioDatabase.General[Child.Name] then
                AudioDatabase.General[Child.Name] = {};
            end

            AddDirectory(Child, AudioDatabase.General[Child.Name]);
        else
            AddDirectory(Child);
        end

    end

end

function AudioDatabase:FromString(p_AudioDir: string): AudioInformation? 
    local Split = string.split(p_AudioDir, '/')
    local Current = AudioDatabase.General;
    
    if AudioDatabase.__Cache[p_AudioDir] then
        local Data = AudioDatabase.__Cache[p_AudioDir].Data;
        local Thread = AudioDatabase.__Cache[p_AudioDir].Thread;

        if typeof(Thread) == 'thread' then
            task.cancel(Thread)
        end

        AudioDatabase.__Cache[p_AudioDir].Thread = task.delay(120, function()
            AudioDatabase.__Cache[p_AudioDir] = nil
        end)

        return table.clone(Data);
    end
    
    for i = 1, #Split do
        local var = Split[i]
        if Current[var] then
            Current = Current[var]
            continue
        end

        return nil;
    end

    if typeof(Current) == 'table' and Current.Id then
        AudioDatabase.__Cache[p_AudioDir] = {
            Data = Current,
            Thread = task.delay(210, function()
                AudioDatabase.__Cache[p_AudioDir] = nil
            end)
        }

        return table.clone(Current);
    end
    
    return nil;
end

return AudioDatabase
