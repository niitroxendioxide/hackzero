--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Camera = require(Client.Libraries.Camera)
local CutsceneFolder = Client.Components.Cutscenes

--
local CutsceneLibrary = {
    __Cache = {},
    __Current = nil,
};


function CutsceneLibrary:Init(): ()
    for _, CutsceneModule in CutsceneFolder:GetDescendants() do
        local Success, CutsceneInstance = pcall(require, CutsceneModule)

        if Success then
            CutsceneLibrary.__Cache[CutsceneInstance.__Name] = CutsceneInstance
        else
            warn(`Cutscene loading error: {CutsceneModule.Name} -> {CutsceneInstance}`)
        end

    end
end

--[[
    Start a cutscene for stuffs
]]
function CutsceneLibrary:Start(Name: string, Data: {any}?): (boolean)
    local CutsceneClass = CutsceneLibrary:Find(Name)
    if not CutsceneClass then
        return false;
    end

    if CutsceneLibrary.__Current then
        return false;
    end

    print("Hello?")
    Camera:MarkUsage(Name)
    CutsceneClass:Play(Data)
    CutsceneLibrary.__Current = CutsceneClass

    CutsceneClass.Completed:Once(function()
        Camera:FreeUsage()
        CutsceneLibrary.__Current = nil
    end)

    return true;
end

function CutsceneLibrary:Find(Name: string): Types.CutsceneClass?
    return CutsceneLibrary.__Cache[Name]
end

return CutsceneLibrary