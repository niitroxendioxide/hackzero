--!strict
--[[
    @niitroxendioxide 2025-10
    
    Audio database for the game.
]]
    
local RunService = game:GetService("RunService")
export type AudioInformation = {
    Id: number | { number },
    Volume: number?,
    Category: string?,
    Priority: string?,
    Loop: boolean?,
}

export type AudioDirectory = {
    [string]: AudioInformation & AudioDirectory,
}

local AudioDatabase = {
    __Cache = {} :: { [string]: { Data: any, Thread: thread } } ,
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
        Walking = {
            Concrete = {
                Id = {  },
            },
        },

        Dodge = { 
            Id = { 108928552267639, 101379165800189, 138149044086182 } 
        },

        Hit_Punch = {
            Id = { 72289516850884, 84842128857669, 127506333286120, 95767179202055 },
        },

        Hit_Sword = { 
            Id = { 131013767176862, 84368388920930, 126781064225579, 106034054871126 },
        },

        Swing_Sword = { 
            Id = { 136959000261275, 81981242471334, 131048650497054 },
        },

        Swing_Punch = { 
            Id = { 95080238134400, 100679914916439, 124096565268359, 70429057878595 },
        }
    }
} :: AudioDirectory

function AddDirectory(p_Directory: Instance | ModuleScript, p_CurrentDirectory: {any}?)
    local CurrentDir = p_CurrentDirectory or AudioDatabase.General;

    if p_Directory:IsA("ModuleScript") then
        CurrentDir[p_Directory.Name] = require(p_Directory) :: any;
    else
        for _, Child in p_Directory:GetChildren() do
            if Child:IsA("ModuleScript") then
                CurrentDir[Child.Name] = require(Child) :: any;
            else
                if not CurrentDir[Child.Name] then
                    CurrentDir[Child.Name] = {};
                end

                AddDirectory(Child, CurrentDir[Child.Name] :: any);
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
                AudioDatabase.General[Child.Name] = {} :: any;
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
    local Starting_Index = if string.lower(Split[1]) == 'general' then 2 else 1

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
    
    for i = Starting_Index, #Split do
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

        return table.clone(Current) :: any;
    end
    
    return nil;
end

return AudioDatabase
