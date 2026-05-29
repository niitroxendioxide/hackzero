local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets:FindFirstChild('Interactables')
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Prompts = require(script.Parent.Prompts)
local Animlib = require(script.Parent.Animation)
local GameEnum = require(Shared.GameEnum)
local EffectsLib = require(Client.Libraries.Effects)


--
export type ChestObjectData = {
    Id: number,
    Opened: boolean,
    Base: BasePart,
    Design: string,
    Model: Model & {AnimationController: AnimationController},
    Prompt: ProximityPrompt,
}

--
local ChestsLibrary = {}
local Chests = {}

function HandleOpeningAnimation(Chest: ChestObjectData, Items: {}, Player: Player?)
    local Model = Chest.Model;
    
    if Chest.Opened then
        Animlib:StopTracksWithTag(Model, 'ChestOpening')

        local OpeningAnimationTrack = Animlib:GetAnim("Interactables.Chest.Open_" .. Chest.Design)
        local Track = Animlib:Play(Model, OpeningAnimationTrack)
        Track:AddTag('ChestOpening')
        

        task.delay(.1, PlayChestOpeningEffect, Chest, Items, Player)
        task.delay(1.5, function()
            if not(Track) or not(Track.IsPlaying) or (Track.Speed < 1) then
                return
            end

            Track:AdjustSpeed(0)
        end)
    elseif not Chest.Opened then
        local PlayingTrack = Animlib:GetTracks('ChestOpening')
        
        if PlayingTrack then
            PlayingTrack:AdjustSpeed(-1)
        end
    end

end

function PlayChestOpeningEffect(Chest: ChestObjectData, Items: {}, Player: Player?)
    EffectsLib:Play('ChestOpening', Chest.Base:GetPivot(), Items or {}, Player)
end

function CreateModelOnBasePart(BasePart: BasePart, Design: string)
    local ChestsFolder = Assets.Chests
    local Model = ChestsFolder:FindFirstChild(Design)
    if not Model then
        return
    end
    
    local Cloned = Model:Clone()
    Cloned:PivotTo(BasePart:GetPivot())
    Cloned.Parent = workspace
    
    return Cloned
end

function ChestsLibrary:CreateWithBase(BasePart: BasePart, Id: number, DesignId: number)
    local Prompt = Prompts:CreatePromptOnPart(BasePart, GameEnum.InteractionType.Chest, "Open", "Chest")
    local Design = GameEnum.KeyLookup(GameEnum.Interactables.Chests, DesignId) or 'Default'

    Prompt:SetAttribute("ChestId", Id)

    local Object: ChestObjectData = {
        Id = Id,
        Opened = false,
        Base = BasePart,
        Design = Design,
        Model = CreateModelOnBasePart(BasePart, Design),
        Prompt = Prompt,
    }

    Chests[Id] = Object
end

function ChestsLibrary:GetById(Id: number): ChestObjectData?
    return Chests[Id]
end


function ChestsLibrary:SetOpenState(Id: number, OpenState: boolean, Items: {}?, Player: Player?): ()
    assert(typeof(OpenState) == "boolean", "Invalid state given")

    local Chest = ChestsLibrary:GetById(Id)
    if not Chest then
        return
    end

    Chest.Opened = OpenState

    if Chest.Opened then
        Chest.Prompt.Enabled = false
    end

    HandleOpeningAnimation(Chest, Items, Player)
end

function ChestsLibrary:Remove(Id: number): boolean
    if not Chests[Id] then
        return false
    end

    Chests[Id] = nil

    return true
end

return ChestsLibrary