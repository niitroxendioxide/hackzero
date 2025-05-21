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
        if not CutsceneModule:IsA("ModuleScript") then continue end
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
    @param Name Cutscene name defined in the module for the cutscene
    @param Data Any extra data that the cutscene might need

    @return Status whether the cutscene could run or not
    @return FailMessage The error message
]]
function CutsceneLibrary:Start(Name: string, Data: {any}?): (boolean, string?)
    local CutsceneClass = CutsceneLibrary:Find(Name)
    if not CutsceneClass then
        return false, "Cutscene not found";
    end

    if CutsceneLibrary.__Current or (Camera:GetCurrentUser() ~= nil) then
        return false, "Cannot interrupt other cutscene";
    end

    Camera:MarkUsage(Name)

    local Success, FailMsg = pcall(function()
        CutsceneClass:Play(Data)
    end)
    if not Success then
        return false, FailMsg
    end

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

function CutsceneLibrary:IsInCutscene()
    return CutsceneLibrary.__Current ~= nil
end

-- @ yields
function CutsceneLibrary:WaitCurrent(): ()
    if CutsceneLibrary.__Current then
        repeat task.wait()
        until CutsceneLibrary.__Current == nil

        task.wait();
    end
end

return CutsceneLibrary