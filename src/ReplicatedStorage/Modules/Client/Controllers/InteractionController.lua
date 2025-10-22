local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = ReplicatedStorage.Modules.Shared.Database

local InterfaceController = require(script.Parent.InterfaceController)
local LocalData = require(ReplicatedStorage.Modules.Client.Libraries.LocalData)
local NPCS = require(ReplicatedStorage.Modules.Client.Libraries.NPCS)
local Prompts = require(ReplicatedStorage.Modules.Client.Libraries.Prompts)
local StageDatabase = require(Database.Stages)
local Chests = require(Client.Libraries.Chests)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Npcs = require(Client.Controllers.LobbyController.NPCS)

local Controller = {
    __Current_Action = {},
}

function Controller:Init()
    ProximityPromptService.PromptTriggered:Connect(function(Prompt, Player)
        if Prompt:GetAttribute("Type") == GameEnum.InteractionType.Chest then
            local ChestId = Prompt:GetAttribute("ChestId")
            local ChestObject = Chests:GetById(ChestId)
            if not ChestObject or ChestObject.Opened then
                return
            end

            Chests:SetOpenState(ChestId, true)

            Network:Fire("ChestInteraction", GameEnum.ChestInteractions.Open, ChestId)
        elseif Prompt:GetAttribute("Type") == GameEnum.InteractionType.NPC then
            Controller:InteractWithNPC(Prompt)
        elseif Prompt:GetAttribute("Type") == GameEnum.InteractionType.LobbyNPC then
            Npcs:TalkToNPC(Prompt:GetAttribute("NpcId"))
        end
    end)
end

function Controller:InteractWithNPC(Prompt: ProximityPrompt)
    local Id = Prompt:GetAttribute("NPCId") :: number
    local NpcObject = NPCS:GetById(Id)
    local NpcName = NpcObject.Name

    local Stage, Act = LocalData:GetStageData()

    local ActData = StageDatabase:GetAct(Stage, Act)

    if ActData.Markers[NpcName] then
        local DialogueComponent = InterfaceController:GetComponent("Dialogue")

        Prompts:DisableAll()

        DialogueComponent:PlaySequence(ActData.Markers[NpcName].Dialogue, true, NpcName)

        DialogueComponent.EventTriggered:Connect(function(Id: number, NpcName: string)
            Network:Fire("NPCInteraction", GameEnum.NPCInteractions.Event, {Id = Id, Name = NpcName})
        end)

        DialogueComponent.Completed:Once(function()
            Prompts:EnableAll()
        end)

        --
        Network:Fire("NPCInteraction", GameEnum.NPCInteractions.Talk, {Name = NpcName})
    end
end

return Controller
