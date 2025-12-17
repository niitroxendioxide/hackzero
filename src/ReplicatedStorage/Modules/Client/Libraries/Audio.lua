--[[
    @niitroxendioxide 2025-10
    
    Used to play audios easily using roblox's new audio system
    It is a quick/utils library for playing audios, and it requires the 
    AudioController to be loaded in order to work. 
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- imports
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local AudioDatabase = require(Shared.Database.Audio)
local AudioController = require(Client.Controllers.AudioController)
local Mock = require(Shared.Utility.Mock)


local AudioLib = {}

-- typedefs
export type AudioCreationData = {
    At: vector | Vector3,
    Volume: number, 
    Category: string, 
    Priority: string?,
    Loop: boolean?,
}

export type EmitterAttachment = Attachment & {
    AudioPlayer: AudioPlayer,
    AudioEmitter: AudioEmitter,
}

function CreateEmitter(p_Location: vector, p_AudioId: string): EmitterAttachment
    local AudioAttachment = Instance.new("Attachment")
    AudioAttachment.Visible = false-- RunService:IsStudio()
    AudioAttachment.Position = p_Location;

    local AudioPlayer = Instance.new("AudioPlayer")
    AudioPlayer.Asset = p_AudioId
    AudioPlayer.Parent = AudioAttachment

    local AudioEmitter = Instance.new("AudioEmitter")
    AudioEmitter.Parent = AudioAttachment

    local Wire = Instance.new("Wire")
    Wire.Parent = AudioAttachment
    Wire.SourceInstance = AudioPlayer
    Wire.TargetInstance = AudioEmitter

    return AudioAttachment
end

function AudioLib:Create(p_AudioId: string, p_CreationData: AudioCreationData): EmitterAttachment
    local Sanitized = p_AudioId;
    if typeof(p_AudioId) == 'number' then
        Sanitized = "rbxassetid://" .. tostring(p_AudioId)
    end

    if not string.match(Sanitized, "rbxassetid://") then
        print("Audio ID is not valid! ", Sanitized)

        return (Mock :: EmitterAttachment);
    end
    
    local Group = AudioController:GetGroup(p_CreationData.Category, p_CreationData.Priority);
    local CategoryVolume = Group.Parent.Volume;
    local PriorityVolume = Group.Volume;

    local Emitter = CreateEmitter(p_CreationData.At :: vector, Sanitized)
    local TrackVolume = p_CreationData.Volume

    Emitter:SetAttribute('TrackVolume', TrackVolume * PriorityVolume)
    Emitter.AudioPlayer.Volume = TrackVolume * PriorityVolume * CategoryVolume
    Emitter.Parent = Group

    return Emitter
end

function AudioLib:PlayFromSound(p_Track: Sound, p_CreationData: AudioCreationData): EmitterAttachment
    local Emitter = self:Create(p_Track.SoundId, p_CreationData) :: EmitterAttachment

    Emitter.AudioPlayer.Play()

    -- cleanup
    Emitter.AudioPlayer.Ended:Once(function()
        Emitter:Destroy()
    end)

    return Emitter
end

function AudioLib:PlayId(p_Id: string | number | { number }, p_CreationData: AudioCreationData): EmitterAttachment
    local g_Id = p_Id;
    if typeof(p_Id) == 'table' then
        g_Id = p_Id[math.random(1, #p_Id)]
    end
    
    local Emitter = self:Create(g_Id, p_CreationData) :: EmitterAttachment

    Emitter.AudioPlayer:Play()

    -- cleanup
    Emitter.AudioPlayer.Ended:Once(function()
        Emitter:Destroy()
    end)

    return Emitter
end

function AudioLib:PlayFromDb(p_AudioDirectory: string, p_AudioLocation: vector | Vector3): EmitterAttachment
    local AudioData = AudioDatabase:FromString(p_AudioDirectory)
    if not AudioData then
        warn("Couldn't find audio source/data from database for lookup key: ", p_AudioDirectory)

        return (Mock :: EmitterAttachment);
    end

    AudioData.At = p_AudioLocation;

    return self:PlayId(AudioData.Id, AudioData)
end

function AudioLib:EmitEffect(p_Position: vector | Vector3, p_Id: string, p_Volume: number?)
    return self:PlayId(p_Id, {
        At = p_Position,
        Volume = p_Volume or 1,
        Category = "Effects",
        Priority = "Medium",
    })
end


return AudioLib