local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = ReplicatedStorage.Modules.Shared.Database
local Assets = ReplicatedStorage.Assets.Interface

local InterfaceController = require(script.Parent.InterfaceController)
local LocalData = require(ReplicatedStorage.Modules.Client.Libraries.LocalData)
local NPCS = require(ReplicatedStorage.Modules.Client.Libraries.NPCS)
local Prompts = require(ReplicatedStorage.Modules.Client.Libraries.Prompts)
local Navigation = require(ReplicatedStorage.Modules.Client.States.Navigation)
local Places = require(ReplicatedStorage.Modules.Shared.Places)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local StageDatabase = require(Database.Stages)
local MissionsDatabase = require(Database.Missions)
local Chests = require(Client.Libraries.Chests)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Npcs = require(Client.Controllers.LobbyController.NPCS)

local Controller = {
    __Current_Action = {},
}

function HandlePromptShown(Prompt: ProximityPrompt)
    local PromptType = Prompt:GetAttribute("Type")

    if PromptType == GameEnum.InteractionType.UIInteraction then
        local PromptOwner = Prompt:FindFirstAncestorOfClass("Model")
        local InterfaceId = PromptOwner:GetAttribute("UIElement")

        local Element = InterfaceController:GetComponent(InterfaceId)
        if Element and Element.ShownPromptInteraction then
            Element:ShownPromptInteraction()
        end
    end
end

function HandleHiddenPrompt(Prompt: ProximityPrompt)
    local PromptType = Prompt:GetAttribute("Type")

    if PromptType == GameEnum.InteractionType.UIInteraction then
        local PromptOwner = Prompt:FindFirstAncestorOfClass("Model")
        local InterfaceId = PromptOwner:GetAttribute("UIElement")

        local Element = InterfaceController:GetComponent(InterfaceId)
        if Element and Element.HiddenPromptInteraction then
            Element:HiddenPromptInteraction()
        end
    end
end

function Controller:Init()
    if Places:IsInPlace("Lobby") then
        Controller:SetupLobbyNPCS()
    end

    ProximityPromptService.PromptShown:Connect(function(GivenPrompt: ProximityPrompt, _: Enum.ProximityPromptInputType)
        if GivenPrompt.Style == Enum.ProximityPromptStyle.Custom then
            Controller:CreatePromptWithCustomDesign(GivenPrompt)
        end

        HandlePromptShown(GivenPrompt)
    end)


    ---

    ProximityPromptService.PromptTriggered:Connect(function(Prompt, Player)
        local PromptType = Prompt:GetAttribute("Type")

        if PromptType == GameEnum.InteractionType.Chest then
            local ChestId = Prompt:GetAttribute("ChestId")
            local ChestObject = Chests:GetById(ChestId)
            if not ChestObject or ChestObject.Opened then
                return
            end

            Network:Fire("ChestInteraction", GameEnum.ChestInteractions.Open, ChestId)
        elseif PromptType == GameEnum.InteractionType.UIInteraction and (Navigation:Get("CanInteract") == true) then
            local PromptOwner = Prompt:FindFirstAncestorOfClass("Model")
            local InterfaceId = PromptOwner:GetAttribute("UIElement")

            local Element = InterfaceController:GetComponent(InterfaceId)
            if Element then
                Element:Set(true)
                Prompt.Enabled = false

                Element:AwaitStateChange(function()  
                    Prompt.Enabled = true
                end)
            end
        elseif PromptType == GameEnum.InteractionType.NPC then
            Controller:InteractWithNPC(Prompt)
        elseif PromptType == GameEnum.InteractionType.LobbyNPC then
            Npcs:TalkToNPC(Prompt:GetAttribute("NpcId"))
        end
    end)

    Network:On("ChestInteraction", function(Player: Player, ChestId: number, Items: {})
        local ChestObject = Chests:GetById(ChestId)
        if not ChestObject or ChestObject.Opened then
            return
        end

        Chests:SetOpenState(ChestId, true, Items, Player)

        if Player == Players.LocalPlayer then
            local UIElement = InterfaceController:GetComponent("ItemNotifications")

            local Count = 0;
            for _, Item in Items do
                if Item[1] == 'Artifact' or Item[1] == 'Drive' then
                    task.delay(2.45 + Count * 0.1, function()
                        UIElement:AddItem(Item[1], Item[2], Item[3])
                    end)

                    Count += 1;
                else
                    UIElement:AddItem(Item[1], Item[2], Item[3])
                end
            end
        end
    end)

    Network:On("ItemObtained", function(Items: {})
        local UIElement = InterfaceController:GetComponent("ItemNotifications")

        local Count = 0;
        for _, Item in Items do
            task.delay(Count * 0.1, function()
                UIElement:AddItem(Item[1], Item[2], Item[3])
            end)

            Count += 1
        end
    end)
end

function Controller:CreatePromptWithCustomDesign(Prompt: ProximityPrompt)
    local CustomPromptDesign = Assets.Lobby.Main.PromptAtt:FindFirstChild('PromptGUI'):Clone()
    local KeyObject = CustomPromptDesign.Background.Key
    CustomPromptDesign.Background.Key.Label.Text = Prompt.KeyboardKeyCode.Name
    CustomPromptDesign.Background.Action.Text = Prompt.ActionText
    CustomPromptDesign.Background.Description.Text = Prompt.ObjectText
    CustomPromptDesign.Parent = Prompt.Parent
    CustomPromptDesign.Background.UIScale.Scale = 0

    KeyObject.UIScale.Scale = 0
    CustomPromptDesign.StudsOffset = vector.zero
    Effects:Tween(CustomPromptDesign.Background.UIScale, { 0.4, 'Back', 'Out' }, {Scale = 1})

    Effects:Tween(CustomPromptDesign, { 0.5, 'Quart', 'Out' }, {StudsOffset = vector.create(4, 0, 0)})
    task.delay(0.15, function()
        Effects:Tween(KeyObject.UIScale, { 0.3, 'Back' }, {Scale = 1})
    end)

    local PressConnection; PressConnection = Prompt.PromptButtonHoldBegan:Connect(function(a0: Player)  
        KeyObject.UIScale.Scale = 0.75
        KeyObject.UIStroke.Thickness = 0.08

        Effects:Tween(KeyObject.UIStroke, { 0.5, 'Back' }, {Thickness = 0.04})
        Effects:Tween(KeyObject.UIScale, { 0.5, 'Back' }, {Scale = 1})
    end)

    Prompt.PromptHidden:Once(function(...)  
        task.spawn(HandleHiddenPrompt, Prompt)
        PressConnection:Disconnect()

        if not KeyObject:FindFirstChild('UIScale') then
            return
        end

        Effects:Tween(KeyObject.UIScale, { 0.2, 'Quad', 'In' }, {Scale = 0})
        Effects:Tween(CustomPromptDesign.Background.UIScale, { 0.45, 'Quad', 'In' }, {Scale = 0.65})

        Effects:Tween(CustomPromptDesign.Background, { 0.3, 'Quad' }, {Transparency = 1})
        for _, Child: Instance in CustomPromptDesign.Background:GetDescendants() do
            if Child:IsA("ImageLabel") then
                Effects:Tween(Child, { 0.3, 'Linear'}, {ImageTransparency = 1})
            elseif Child:IsA("GuiObject") or Child:IsA("UIStroke") then
                Effects:Tween(Child, { 0.3, 'Linear'}, {Transparency = 1})
            elseif Child:IsA("TextLabel") then
                Effects:Tween(Child, { 0.3, 'Linear'}, {TextTransparency = 1, TextStrokeTransparency = 1})  
            end
        end
        Effects:CleanUp(CustomPromptDesign, 0.5)
    end)
end

function Controller:InteractWithNPC(Prompt: ProximityPrompt)
    local Id = Prompt:GetAttribute("NPCId") :: number
    local NpcObject = NPCS:GetById(Id)
    local NpcName = NpcObject.Name

    local Data = LocalData:GetStageData()

    local NpcData = nil;
    if Data.MissionId == nil then
        local StageData = StageDatabase:GetAct(Data.Stage, Data.Act)
        NpcData = StageData.Markers[NpcName]
    elseif Data.MissionId ~= nil then
        local StageData = MissionsDatabase:Get(Data.MissionId)
        NpcData = StageData.Triggers[NpcName]
    end

    if NpcData then
        local DialogueComponent = InterfaceController:GetComponent("Dialogue")

        Prompts:DisableAll()

        DialogueComponent:PlaySequence(NpcData.Markers[NpcName].Dialogue, true, NpcName)

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


---- Setting up npcs
function Controller:SetupLobbyNPCS()
    local NPCFolder = workspace:WaitForChild("World"):FindFirstChild("Map"):FindFirstChild("Design"):FindFirstChild("NPCS")
    

    --- Chaos Control
    

    --- Mission NPCS
    for _, NPC in NPCFolder:GetChildren() do
        local Id = NPC.Name;
        print(Id)

        if Id == 'ChaosControlRig' then
            NPC:SetAttribute("UIElement", "ChaosControl")

            Prompts:CreatePromptOnPart(NPC.PrimaryPart, GameEnum.InteractionType.UIInteraction, "Interact", "Check Chaos Control", 8)
        elseif Id == 'MissionNPCRig' then
            NPC:SetAttribute("UIElement", "Interactions")

            Prompts:CreatePromptOnPart(NPC.PrimaryPart, GameEnum.InteractionType.UIInteraction, "Interact", "Check Mission Desk", 18)
        elseif Id == 'SummonNPC' then
            NPC:SetAttribute("UIElement", "Summon")

            Prompts:CreatePromptOnPart(NPC.PrimaryPart, GameEnum.InteractionType.UIInteraction, "Interact", "Talk to Agent Recruiter", 18)
        end
    end
end

return Controller
