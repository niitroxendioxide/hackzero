local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Prompts = require(script.Parent.Prompts)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)


--
export type ChestObjectData = {
    Id: number,
    Opened: boolean,
    Base: BasePart,
}

--
local ChestsLibrary = {}
local Chests = {}

function ChestsLibrary:CreateWithBase(BasePart: BasePart, Id: number)
    local Prompt = Prompts:CreatePromptOnPart(BasePart, GameEnum.InteractionType.Chest, "Open", "Chest")

    Prompt:SetAttribute("ChestId", Id)

    local Object: ChestObjectData = {
        Id = Id,
        Opened = false,
        Base = BasePart,
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
end

function ChestsLibrary:Remove(Id: number): boolean
    if not Chests[Id] then
        return false
    end

    Chests[Id] = nil

    return true
end

return ChestsLibrary