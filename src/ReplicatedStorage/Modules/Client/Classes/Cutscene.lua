local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Assets = ReplicatedStorage:FindFirstChild("Assets")

local Camera = require(Client.Libraries.Camera)
local Signal = require(Shared.Utility.Signal)
local Types = require(Shared.Types)
local EffectsUtil = require(Shared.Utility.Effects)
local AnimLib = require(Client.Libraries.Animation)
local CharactersLib = require(Client.Libraries.Characters)

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
    self.__Objects = {}
    self.__Thread = nil;

    return self
end

function CutsceneClass.GetPlayerEnvironment(self: Types.CutsceneClass): {}
    local Current = CharactersLib:GetCurrent(Players.LocalPlayer:GetAttribute("ReplicationId"))

    return {
        Model = Current:GetModel(),
        CFrame = Current:GetPivot(),
        AgentName = Current.Name
    }
end

--
function CutsceneClass.Sequence(self: Types.CutsceneClass, Data: {}): ()
    print("Cutscene sequence", self.__Name, "began!")
    -- empty method!
end

function CutsceneClass.AnimateCamera(self: Types.CutsceneClass, At: CFrame, Animation: string): (AnimationTrack)?
    local Rig = Assets.Characters:FindFirstChild('CameraRig');
    if not(Rig) or not(Camera:GetCurrentUser() == self.__Name) then
        return;
    end

    local RenderStepKey = self.__Name .. "CameraRenderer"
    RunService:UnbindFromRenderStep(RenderStepKey)

    local NewCameraRig = self.__Objects.CameraRig or Rig:Clone()
    self.__Objects.CameraRig = NewCameraRig
    self.__Objects.CameraRig:PivotTo(At)
    self.__Objects.CameraRig.Parent = (workspace:FindFirstChild("World") :: Folder):FindFirstChild("Effects")

    local AnimObject = AnimLib:GetAnim('Cutscenes.'..Animation)
    local Track = AnimLib:Play(self.__Objects.CameraRig, AnimObject)

    RunService:BindToRenderStep(RenderStepKey, Enum.RenderPriority.Camera.Value, function(delta: number)
        if Camera:GetCurrentUser() ~= self.__Name then
            RunService:UnbindFromRenderStep(RenderStepKey)

            return
        end

        workspace.CurrentCamera.CFrame = NewCameraRig.CameraReference.CFrame
    end)

    Track.Stopped:Once(function()
        Track:Destroy()
    end)

    return Track;
end

function CutsceneClass.MoveCamera(self: Types.CutsceneClass, To: CFrame, Info: {any}): Tween?
    if not(Camera:GetCurrentUser() == self.__Name) then
        return
    end

    if Info then
        local CameraTween = Camera:TweenTo(To, Info)
        self:Add(CameraTween)

        return CameraTween
    end

    workspace.CurrentCamera.CFrame = To

    return;
end

function CutsceneClass.SetFOV(self: Types.CutsceneClass, FOV: number, Info: {any})
    if not(Camera:GetCurrentUser() == self.__Name) then
        return
    end


    if Info then
        local Tween = EffectsUtil:Tween(workspace.CurrentCamera, Info, {FieldOfView = FOV})

        self:Add(Tween)

        return Tween;
    end

    workspace.CurrentCamera.FieldOfView = FOV;

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

function CutsceneClass.Wait(self: Types.CutsceneClass, Time: number)
    local Counter = 0;

    repeat
        local Delta = task.wait()
        Counter += Delta
    until (Counter >= Time) or (Counter >= self.__Time)
end

function CutsceneClass.Remove(self: Types.CutsceneClass, Item: any): ()
    local EntryFoundIndex = table.find(self.__Cache, Item)

    if EntryFoundIndex then
        table.remove(self.__Cache, EntryFoundIndex)
    end
end

function CutsceneClass.End(self: Types.CutsceneClass)
    self.Completed:Fire()

    --
    self:CleanUp()
    self.__Active = false

    if self.__Thread ~= nil and self.__Thread ~= coroutine.running() then
        task.cancel(self.__Thread)
        self.__Thread = nil
    end

    self:SetFOV(70)
end

return CutsceneClass