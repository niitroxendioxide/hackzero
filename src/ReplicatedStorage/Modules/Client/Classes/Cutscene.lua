--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Camera = require(Client.Libraries.Camera)
local Signal = require(Shared.Utility.Signal)
local Types = require(Shared.Types)
local EffectsUtil = require(Shared.Utility.Effects)

--
local CutsceneClass = {}
CutsceneClass.__index = CutsceneClass

function CutsceneClass.new(Name: string, Time: number): Types.CutsceneClass
    local self = setmetatable({}, CutsceneClass)
    self.Completed = Signal.new()

    --
    self.__Name = Name
    self.__Time = Time or 10
    self.__Active = false
    self.__Cache = {}
    self.__Thread = nil;

    return self
end

--
function CutsceneClass.Sequence(self: Types.CutsceneClass, Data: {}): ()
    print("Cutscene sequence", self.__Name, "began!")
    -- empty method!
end

function CutsceneClass.MoveCamera(self: Types.CutsceneClass, To: CFrame, Info: {any}): Tween?
    if not(Camera:GetCurrentUser() == self.__Name) then
        return
    end

    if Info then
        local CameraTween = Camera:TweenTo(To, Info)

        return CameraTween
    end

    workspace.CurrentCamera.CFrame = To

    return;
end

function CutsceneClass.Play(self: Types.CutsceneClass, Data: {})
    if self.__Active then
        return
    end

    if self.__Thread then
        task.cancel(self.__Thread)
        self.__Thread = nil
    end

    self.__Active = true
    self:Add(task.spawn(function()
        self:Sequence(Data)
    end))

    --
    self.__Thread = task.delay(self.__Time, function()
        self:End()
    end)
end

function CutsceneClass.CleanUp(self: Types.CutsceneClass)
    for _, Item in self.__Cache do
        if typeof(Item) == 'thread' then
            if Item ~= coroutine.running() then
                task.cancel(Item)
            end
        else
            EffectsUtil:CleanUp(Item, 0)
        end
    end
end

function CutsceneClass.Add(self: Types.CutsceneClass, Item: any): ()
    table.insert(self.__Cache, Item)
end

function CutsceneClass:Wait(Time: number)
    local Counter = 0;

    repeat
        local Delta = task.wait()
        Counter += Delta
    until Counter >= Time
end

function CutsceneClass.Remove(self: Types.CutsceneClass, Item: any): ()
    local EntryFoundIndex = table.find(self.__Cache, Item)

    if EntryFoundIndex then
        table.remove(self.__Cache, EntryFoundIndex)
    end
end

function CutsceneClass.End(self: Types.CutsceneClass)
    self:CleanUp()
    self.__Active = false

    if self.__Thread then
        task.cancel(self.__Thread)
        self.__Thread = nil
    end

    --
    self.Completed:Fire()
end

return CutsceneClass