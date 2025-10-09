local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AudioController = require(ReplicatedStorage.Modules.Client.Controllers.AudioController)
--[[
    @niitroxendioxide 2025-10

    Used to play audios easily using roblox's new audio system
]]
local AudioLib = {}


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

function AudioLib:Create(Track: Sound, p_CreationData: AudioCreationData): EmitterAttachment
    local Group = AudioController:GetGroup(p_CreationData.Category, p_CreationData.Priority);
    local GroupVolume = Group.Volume

    local Emitter = CreateEmitter(p_CreationData.At :: vector, Track.SoundId)
    local TrackVolume = p_CreationData.Volume

    Emitter:SetAttribute('TrackVolume', TrackVolume)
    Emitter.AudioPlayer.Volume = TrackVolume * GroupVolume
    Emitter.Parent = Group

    return Emitter
end

function AudioLib:Play(Track: Sound, p_CreationData: AudioCreationData): EmitterAttachment
    local Emitter = self:Create(Track, p_CreationData)

    Emitter.AudioPlayer.Play()

    return Emitter
end



return AudioLib