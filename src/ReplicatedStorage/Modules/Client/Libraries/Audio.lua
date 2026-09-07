--[[
    @niitroxendioxide 2025-10
    
    Used to play audios easily using roblox's new audio system
    It is a quick/utils library for playing audios, and it requires the 
    AudioController to be loaded in order to work. 
]]


const ReplicatedStorage = game:GetService("ReplicatedStorage")
const _RunService = game:GetService("RunService")

-- imports
const Client = ReplicatedStorage.Modules.Client
const Shared = ReplicatedStorage.Modules.Shared

const Effects = require(Shared.Utility.Effects)
const AudioDatabase = require(Shared.Database.Audio)
const AudioController = require(Client.Controllers.AudioController)
const Mock = require(Shared.Utility.Mock)

const EMPTY_AUDIO_ID = "rbxassetid://0"
const POOL_MIN_SIZE = 32;
const AudioLib = {
    __Cached_Emitters = {} :: { EmitterAttachment },
    __In_Use = {} :: { EmitterAttachment },
    __Threads = {} :: { [EmitterAttachment]: thread } , 
}

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

function FetchPossibleEmitter(p_Location: vector, p_AssetId: number)
    if #AudioLib.__Cached_Emitters >= 1 then
        local FetchedEmitter = table.remove(AudioLib.__Cached_Emitters, 1);
        FetchedEmitter.AudioPlayer.Asset = p_AssetId;
        FetchedEmitter.AudioPlayer.Volume = 0.5;
        FetchedEmitter.Position = p_Location;

        if typeof(AudioLib.__Threads[FetchedEmitter]) == 'thread' then
            task.cancel(AudioLib.__Threads[FetchedEmitter]);
        end
        
        table.insert(AudioLib.__In_Use, FetchedEmitter);

        return FetchedEmitter;
    end

    local Borrowed = CreateEmitter(p_Location, p_AssetId);
    Borrowed:AddTag('Borrowed');

    table.insert(AudioLib.__In_Use, Borrowed);

    return Borrowed
end

function ReturnUsedEmitter(p_Emitter: EmitterAttachment)
    local InUseIndex = table.find(AudioLib.__In_Use, p_Emitter);
    if InUseIndex then
        table.remove(AudioLib.__In_Use, InUseIndex);
        table.insert(AudioLib.__Cached_Emitters, p_Emitter);

        if not p_Emitter:HasTag('Borrowed') then
            return
        end

        AudioLib.__Threads[p_Emitter] = task.delay(60, function()
            local InCacheIndex = table.find(AudioLib.__Cached_Emitters, p_Emitter);
            if InCacheIndex then
                table.remove(AudioLib.__Cached_Emitters, InCacheIndex);
            end

            p_Emitter:Destroy();
        end)
    end
end

function AudioLib:Init()
    AudioLib.__Cached_Emitters = {}

    for i = 1, POOL_MIN_SIZE do
        local NewEmitter = CreateEmitter(vector.zero, EMPTY_AUDIO_ID) 

        table.insert(AudioLib.__Cached_Emitters, NewEmitter);
    end
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
    
    local Group = AudioController:GetGroup(p_CreationData.Category or 'Effects', p_CreationData.Priority);
    local CategoryVolume = Group.Parent.Volume;
    local PriorityVolume = Group.Volume;

    local Emitter =  FetchPossibleEmitter(p_CreationData.At :: vector, Sanitized) --CreateEmitter(p_CreationData.At :: vector, Sanitized)
    local TrackVolume = p_CreationData.Volume or 0.5

    Emitter:SetAttribute('TrackVolume', TrackVolume * PriorityVolume)
    Emitter.AudioPlayer.Volume = TrackVolume * PriorityVolume * CategoryVolume
    Emitter.Parent = Group

    return Emitter
end

function AudioLib:PlayFromSound(p_Track: Sound, p_CreationData: AudioCreationData): EmitterAttachment
    local Emitter = self:Create(p_Track.SoundId, p_CreationData) :: EmitterAttachment

    Emitter.AudioPlayer.Play()

    Emitter.AudioPlayer.Ended:Once(function()
        ReturnUsedEmitter(Emitter);
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
    Emitter.AudioPlayer.Ended:Once(function()
        ReturnUsedEmitter(Emitter);
    end)

    return Emitter
end

function AudioLib:FadeOutAudio(p_Attachment: EmitterAttachment, p_Time: number)
    if typeof(p_Attachment) ~= 'Instance' or not p_Attachment:FindFirstChild('AudioPlayer') then
        return;
    end

    Effects:Tween(p_Attachment.AudioPlayer, { p_Time or 0.25 }, {Volume = 0});
    Effects:CleanUp(p_Attachment, p_Time or 0.25)
end


--p_Type: string?, p_Priority: string?

--[[
    @param p_AudioDirectory: "General/Effects/Hit_Punch", example of a directory, if 'General' is not specified, it'll automatically look up in there, so you can start without it.
    @param p_AudioLocation: World position in 3d, [x,y,z] of where the audio is supossed to be at
]]
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