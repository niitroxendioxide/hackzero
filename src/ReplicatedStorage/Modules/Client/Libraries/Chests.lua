local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets:FindFirstChild('Interactables')
local Shared = ReplicatedStorage.Modules.Shared

local Prompts = require(script.Parent.Prompts)
local Animlib = require(script.Parent.Animation)
local Effects = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)


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

function HandleOpeningAnimation(Chest: ChestObjectData)
    local Model = Chest.Model;
    
    if Chest.Opened then
        Animlib:StopTracksWithTag(Model, 'ChestOpening')

        local OpeningAnimationTrack = Animlib:GetAnim("Interactables.Chest.Open_" .. Chest.Design)
        local Track = Animlib:Play(Model, OpeningAnimationTrack)
        Track:AddTag('ChestOpening')
        

        task.delay(.1, PlayChestOpeningEffect, Chest)
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

function PlayChestOpeningEffect(Chest: ChestObjectData)
    local Vfx = ReplicatedStorage.Assets.Effects.General.Interactions.OpenChest:Clone()
    Vfx:PivotTo(Chest.Base:GetPivot() * CFrame.new(0, 1, 0))
    Vfx.Parent = workspace.World.Effects
    Effects:Emit(Vfx, true)
    Effects:CleanUp(Vfx, 2)
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


function ChestsLibrary:SetOpenState(Id: number, OpenState: boolean): ()
    assert(typeof(OpenState) == "boolean", "Invalid state given")

    local Chest = ChestsLibrary:GetById(Id)
    if not Chest then
        return
    end

    Chest.Opened = OpenState

    if Chest.Opened then
        Chest.Prompt.Enabled = false
    end

    HandleOpeningAnimation(Chest)
end

function ChestsLibrary:Remove(Id: number): boolean
    if not Chests[Id] then
        return false
    end

    Chests[Id] = nil

    return true
end

return ChestsLibrary