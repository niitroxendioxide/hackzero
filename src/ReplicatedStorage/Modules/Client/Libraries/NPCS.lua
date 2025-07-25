local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Animation = require(script.Parent.Animation)
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Prompts = require(script.Parent.Prompts)

local Entities = {}
local Library = {}

function Library:CreateWithBase(BasePart: BasePart)
    local Id = #Entities + 1

    local NPCObject = {
        Prompt = Prompts:CreatePromptOnPart(BasePart, GameEnum.InteractionType.NPC, 'Talk', BasePart.Name),
        Active = true,
        Id = Id,
        Name = BasePart.Name
    }

    NPCObject.Prompt:SetAttribute("NPCId", Id)

    --
    local NPCModel = Assets.Characters.Agents.Template:Clone()
    NPCModel.PrimaryPart.Anchored = true
    NPCModel:PivotTo(BasePart.CFrame)
    NPCModel.Parent = workspace.World.Effects

    local Object = Animation:GetAnim("General.NPC.Idle")
    Animation:Play(NPCModel, Object)
    --

    table.insert(Entities, NPCObject)
end

function Library:GetById(Id: number)
    return Entities[Id]
end

function Library:RemoveById(Id: number)
    for i = 1, #Entities do
        if Entities[i].Id == Id then
            table.remove(Entities, i)

            break
        end
    end
end

return Library