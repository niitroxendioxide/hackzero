local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- imports
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local GameEnum = require(Shared.GameEnum)
--
local Controller = {}

-- Constants
local AUDIO_CATEGORIES = {
    "Effects",
    "Voices",
    "Music",
    "Ambience",
}

local AUDIO_PRIORITY = {'High', 'Medium', 'Low'}

function CreateOutput()
    local Listener = workspace.Camera:FindFirstChild("AudioListener") or Instance.new("AudioListener")
    Listener.Parent = workspace.Camera

    local OutputDevice = SoundService:FindFirstChild("AudioDeviceOutput") or Instance.new("AudioDeviceOutput")
    OutputDevice.Parent = SoundService

    if not workspace.Camera:FindFirstChild("output_wire") then
        local new_wire = Instance.new("Wire")
        new_wire.Name = "output_wire"
        new_wire.Parent = workspace.Camera
        new_wire.SourceInstance = Listener
        new_wire.TargetInstance = OutputDevice
    end
end

function Controller:Init()
    CreateOutput()

    local Audios = Instance.new("Folder")
    Audios.Name = "Sounds"
    Audios.Parent = workspace.World

    local Group = Instance.new("SoundGroup")
    Group.Name = "Master"
    Group.Parent = Audios

    for _, Category in AUDIO_CATEGORIES do
        local SubGroup = Instance.new("SoundGroup")
        SubGroup.Name = Category
        SubGroup.Parent = Group

        for _, Priority in AUDIO_PRIORITY do
            local Sound = Instance.new("SoundGroup")
            Sound.Name = Priority
            Sound.Parent = SubGroup
        end
    end
end

function Controller:GetGroup(Category: string, Priority: string?, Base: boolean?)
    local Master = workspace.World:FindFirstChild("Sounds"):FindFirstChild("Master")
    if not Master or not Master:FindFirstChild(Category) then
        return Master
    end

    if Base then
        return Master:FindFirstChild(Category)
    end

    return Master:FindFirstChild(Category):FindFirstChild(Priority or GameEnum.AudioPriorities.Medium)
end

function Controller:EditVolume(Category: string, Value: number)
    local Group = self:GetGroup(Category, nil, true)
    if not Group then
        return
    end

    Group.Volume = math.clamp(Value, 0, 2)

    for _, ObjInstance in Group:GetDescendants() do
        if not ObjInstance:IsA("Attachment") then
            continue
        end

        local Volume = ObjInstance:GetAttribute("TrackVolume")
        if typeof(Volume) ~= 'number' then
            continue
        end

        ObjInstance.AudioPlayer.Volume = Volume * Group.Volume
    end
end

return Controller