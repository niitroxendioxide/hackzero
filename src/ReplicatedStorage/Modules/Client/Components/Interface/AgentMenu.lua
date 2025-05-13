local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets
local World = workspace:FindFirstChild("World")


local Types = require(Shared.Types)
local Camera = require(Client.Libraries.Camera)
local Fetcher = require(Client.Libraries.Fetcher)
local Cutscenes = require(Client.Libraries.Cutscenes)
local LocalData = require(Client.Libraries.LocalData)
local _GameEnum = require(Shared.GameEnum)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)
local CharacterDatabase = require(Database.Characters)

--
export type FilterFunction = (Artifact: Frame & {Slot: NumberValue, Type: StringValue}) -> (boolean)
local RoomLocations = World:FindFirstChild("LobbyCutscenes")
if RoomLocations then
    RoomLocations = RoomLocations:FindFirstChild("AgentsRoom").Used
end

--
local Component = ComponentClass.new(script.Name, 'Lobby', {KeyToBind = Enum.KeyCode.C}) :: Types.UIComponent & {FilterArtifacts: (self: Types.UIComponent, FilterFunction) -> ()}
local Scope = Component:GetScope()

local States = {
    __Current_Model = nil,
    __Current_Agent = nil,
    __Current_Tab = Scope:Value(""),
    __Current_Selected_Item = '',
    __Current_Selected_Item_Object = nil,
    __Current_Slot_Picked = 0,
}

--
local function SwitchModel(Name: string)
    if States.__Current_Model then
        States.__Current_Model:Destroy()
    end

    local CharacterModel = Assets.Characters.Agents:FindFirstChild(Name)
    if CharacterModel then
        local Cloned = CharacterModel:Clone()
        Cloned.PrimaryPart.Anchored = true;
        Cloned:PivotTo(RoomLocations.CharacterPlace.CFrame)
        Cloned.Parent = World.Entities.Appearances

        States.__Current_Model = Cloned
    end
end

local function CreateAgentIcons(): ()
    local Frame = Component:GetFrame()

    for _, Obj in Frame.Agents.Holder:GetChildren() do
        if Obj:IsA("Frame") then
            Obj:Destroy()
        end
    end

    --
    local AgentsTable = Fetcher:FetchAgents()
    if #AgentsTable <= 0 then
        Component:Set(false)

        return
    end

    local LastAgent;

    for _, Agent in AgentsTable do
        local AgentName = Agent.Name
        local AgentIcon = Assets.Interface.Agents.AgentIcon:Clone()

        AgentIcon.Btn.MouseButton1Click:Connect(function()
            Component:SelectAgent(Agent)
        end)

        AgentIcon.AgentName.Text = AgentName
        AgentIcon.Parent = Frame.Agents.Holder

        LastAgent = Agent;
    end

    Component:SelectAgent(LastAgent)
end

--
function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("AgentMenu", true)

	return Main;
end

function Component:Init()
    --
    local MainFrame = Component:GetFrame()

    --
    Component:BindToStateChange(function(State: boolean)
        if State then
            Camera:MarkUsage("AgentMenu")

            CreateAgentIcons()

            States.__Current_Tab:set("Stats")

            --
        else
            States.__Current_Agent = nil
            Camera:FreeUsage()
        end
    end)

    for _, Button in MainFrame.Tabs:GetChildren() do
        if not Button:FindFirstChild("Btn") then continue end

        Button.Btn.MouseButton1Click:Connect(function()
            States.__Current_Tab:set(Button.Name)
        end)
    end

    Scope:Observer(States.__Current_Tab):onChange(function()
        local Tabs = MainFrame:FindFirstChild("Tabs")
        local CurrentTab = Component:Peek(States.__Current_Tab)

        for _, Tab in Tabs:GetChildren() do
            if not Tab:IsA("Frame") then continue end

            if Tab.Name == CurrentTab then
                EffectUtil:Tween(Tab.UIScale, {.25, 'Back', 'Out'}, {Scale = 1.25})
            else
                EffectUtil:Tween(Tab.UIScale, {.25}, {Scale = 1})
            end
        end

        local Frame = MainFrame:FindFirstChild(CurrentTab)

        if Frame then
            Frame.Visible = true

            Component:SelectAgent(States.__Current_Agent)

            local StringTabs = {"Items", "Stats", "Skills"}
            for _, SubFrame in MainFrame:GetChildren() do
                if table.find(StringTabs, SubFrame.Name) and SubFrame ~= Frame then
                    SubFrame.Visible = false
                end
            end
        end
    end)
end


--
function Component:CheckAvailable(): boolean
    if Cutscenes:IsInCutscene() then
        return false
    end

    return true
end

function Component:SelectAgent(AgentData: Types.ClientAgentData)
    if States.__Current_Agent == nil then
        Camera:TweenTo(RoomLocations.StatsTab.CFrame)
    end

    States.__Current_Agent = AgentData

    SwitchModel(AgentData.Name)

    --
    local CurrentTab = Component:Peek(States.__Current_Tab)

    if CurrentTab == "Items" then
        Component:ShowArtifacts(AgentData)
    elseif CurrentTab == "Stats" then
        Component:ShowStats(AgentData)
    end
end

function Component:AddArtifact(Artifact: Types.PlayerArtifactData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Holder = ItemsFrame.List.List :: ScrollingFrame

    for _, ExistingItem in Holder:GetChildren() do
        if not ExistingItem:IsA("Frame") then continue end
        if ExistingItem.Id.Value == Artifact.Id then return end
    end

    local NewObject = Assets.Interface.Agents.Items.ListItemArtifact:Clone()
    NewObject.Name = Artifact.Id
    NewObject.Id.Value = Artifact.Id
    NewObject.Slot.Value = Artifact.Slot
    NewObject.Type.Value = Artifact.Name
    NewObject.Used.Visible = Artifact.Equipped ~= nil
    NewObject.Button.MouseButton1Click:Connect(function()
        if States.__Current_Selected_Item_Object ~= NewObject and States.__Current_Selected_Item_Object ~= nil then
            States.__Current_Selected_Item_Object.Selected.Visible = false
            States.__Current_Selected_Item_Object.UsedSelected.Visible = false
        elseif States.__Current_Selected_Item_Object == NewObject then
            States.__Current_Selected_Item = ''
            States.__Current_Selected_Item_Object = nil

            NewObject.Selected.Visible = false
            NewObject.UsedSelected.Visible = false

            Component:ShowArtifactInfo(nil)
            return
        end

        States.__Current_Selected_Item = Artifact.Id
        States.__Current_Selected_Item_Object = NewObject

        if not NewObject.Used.Visible then
            NewObject.Selected.Visible = true
            NewObject.UsedSelected.Visible = false
        else
            NewObject.Selected.Visible = false
            NewObject.UsedSelected.Visible = true
        end

        --
        Component:ShowArtifactInfo(Artifact)
    end)

    NewObject.Parent = Holder
end

function Component:RemoveArtifact(Id: string)
    -- not implemented
    warn("Not implemented yet!")
end

function Component:ShowArtifactInfo(Artifact: Types.PlayerArtifactData?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local DataFrame = ItemsFrame.Data

    for _, SubStat in DataFrame.SubStatList:GetChildren() do
        if SubStat:IsA("Frame") then
            SubStat:Destroy()
        end
    end

    if Artifact == nil then
        DataFrame.Visible = false;

        return
    end

    DataFrame.Visible = true;

    DataFrame.ArtifactName.Text = Artifact.Name
    DataFrame.Level.Text = `Level: {Artifact.Level}`

    local MainStatName = next(Artifact.Stats.Main_Stat)
    DataFrame.MainStat.MainName.Text = string.gsub(MainStatName, '_', ' ')
    DataFrame.MainStat.Value.Text = tostring(Artifact.Stats.Main_Stat[MainStatName])..(if MainStatName:find('%%') then '%' else '')

    for StatName, StatValue in Artifact.Stats.Sub_Stats do
        local NewAsset = Assets.Interface.Agents.Items.ArtifactSubStat:Clone()
        NewAsset.SubName.Text = string.gsub(StatName, '_', " ")
        NewAsset.Value.Text = StatValue
        NewAsset.Parent = DataFrame.SubStatList
    end
end

function Component:ShowArtifacts(AgentData: Types.ClientAgentData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsFolder = ItemsFrame.Artifacts.Items

    ItemsFrame.Artifacts.UIScale.Scale = 0

    EffectUtil:Tween(ItemsFrame.Artifacts.UIScale, {.3, 'Cubic', 'Out'}, {Scale = 1})

    --
    for _, Artifact in LocalData:GetArtifacts() do
        Component:AddArtifact(Artifact)
    end

    Component:SelectArtifactSlot(0)

    --
    task.spawn(function()
        local Angle = math.random(0, 360);
        while ItemsFrame.Visible do
            local Delta = task.wait()
            Angle += Delta * 35

            ItemsFrame.Artifacts.RingDecor.Img.Rotation = Angle
        end
    end)

    --
    local SlotsFrames = {}
    for i = 1, 6 do
        local Slot = ItemsFolder:FindFirstChild("Slot"..i)
        if Slot then
            SlotsFrames[i] = Slot
            Slot.UIScale.Scale = 0

            task.delay(i * 0.05, function()
                EffectUtil:Tween(Slot.UIScale, {.25, 'Back'}, {Scale = 1})
            end)

            continue
        end

        local Angle = math.pi / 3 * i + (math.pi/6)
        local Cos = math.cos(Angle)
        local Sin = math.sin(Angle)

        local NewSlot = Assets.Interface.Agents.Items.ArtifactSlot:Clone()
        NewSlot.Item.Level.Text = "Lvl. "..math.random(1, 99);
        NewSlot.Name = "Slot"..i
        NewSlot.Position = UDim2.fromScale(Cos * .5 + .5, Sin * 0.5 + .5)
        NewSlot.Parent = ItemsFolder

        SlotsFrames[i] = NewSlot

        local SelectButton = NewSlot.Select :: TextButton
        local Tween: Tween;

        SelectButton.MouseButton1Click:Connect(function()
            NewSlot.UIScale.Scale = .85
            Tween = EffectUtil:Tween(NewSlot.UIScale, {.3, 'Back'}, {Scale = 1.1})

            if States.__Current_Slot_Picked == i then
                Component:SelectArtifactSlot(0)

                return
            end

            Component:SelectArtifactSlot(i)
        end)

        SelectButton.MouseEnter:Connect(function()
            if Tween then
                Tween:Cancel()
                Tween:Destroy()
            end

            Tween = EffectUtil:Tween(NewSlot.UIScale, {.25, 'Quad'}, {Scale = 1.1})
        end)

        SelectButton.MouseLeave:Connect(function()
            if Tween then
                Tween:Cancel()
                Tween:Destroy()
            end

            EffectUtil:Tween(NewSlot.UIScale, {.25, 'Quad'}, {Scale = 1})
        end)

        --
        NewSlot.UIScale.Scale = 0

        task.delay(i * 0.05, function()
            EffectUtil:Tween(NewSlot.UIScale, {.25, 'Back'}, {Scale = 1})
        end)

        -- Connect functionality
    end

    --
    Camera:TweenTo(RoomLocations.ArtifactsTab.CFrame, {.6, 'Cubic'})
end

function Component:FilterArtifacts(Filter: FilterFunction): ()
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsList = ItemsFrame.List.List

    for _, Artifact in ItemsList:GetChildren() do
        if not Artifact:IsA('Frame') then continue end
        Artifact.Visible = Filter(Artifact)
    end

    if typeof(States.__Current_Selected_Item_Object) ~= nil and States.__Current_Selected_Item_Object.Visible == false then
        Component:ShowArtifactInfo(nil)
    end
end

function Component:SelectArtifactSlot(SlotId: number?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsList = ItemsFrame.List

    local OldSlot = ItemsFrame.Artifacts.Items:FindFirstChild('Slot'..States.__Current_Slot_Picked)
    if OldSlot then
        OldSlot.Outline.Visible = false
    end

    if not(typeof(SlotId) == 'number') or (SlotId < 1) or (SlotId > 6) then
        ItemsList.Visible = false
        States.__Current_Slot_Picked = 0

        return;
    end

    local NewSlot = ItemsFrame.Artifacts.Items:FindFirstChild('Slot'..SlotId)
    NewSlot.Outline.Visible = true

    States.__Current_Slot_Picked = SlotId
    ItemsList.Visible = true

    --
    Component:FilterArtifacts(function(ArtifactFrame)
        return ArtifactFrame.Slot.Value == SlotId
    end)
end

function Component:UpdateSlotInfo(SlotId: number, Artifact: Types.PlayerArtifactData): ()
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Artifacts = ItemsFrame.Artifacts

    local SlotFrame = Artifacts.Items:FindFirstChild('Slot'..SlotId)

    if Artifact == nil then
        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = false
        end

        SlotFrame.Plus.Visible = true
    else
        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = true
        end

        SlotFrame.Item.Tier.Text = Artifact.Tier
        SlotFrame.Item.Level.Text = Artifact.Level

        SlotFrame.Plus.Visible = false
    end
end


--
function Component:ShowStats(AgentData: Types.ClientAgentData)
    --
    local Frame = self:GetFrame()
    local AgentStats = CharacterDatabase:GetStatsAtLevel(AgentData.Name, AgentData.Level)
    local AgentInfo = CharacterDatabase:GetCharacterData(AgentData.Name)

    Camera:TweenTo(RoomLocations.StatsTab.CFrame, {.6, 'Cubic'})

    --
    for _, Obj in Frame.Stats.ValuesArea.Holder:GetChildren() do
        if Obj:IsA("UIGridLayout") then continue end

        Obj:Destroy()
    end

    local Ignored = {"Penetration", "Jog_Speed", "Walk_Speed", "Sprint_Speed"}
    for Stat, Value in AgentStats do
        if table.find(Ignored, Stat) then continue end

        local NewFrame = Assets.Interface.Agents.Stats.Stat:Clone()
        NewFrame.StatName.Text = string.gsub(Stat, "_", " ")
        NewFrame.StatValue.Text = Value
        NewFrame.Parent = Frame.Stats.ValuesArea.Holder
    end

    --
    local AgentDataFrame = Frame.Stats.AgentData
    AgentDataFrame.AgentFaction.Text = AgentInfo.Faction
    AgentDataFrame.AgentFullName.Text = AgentInfo.Display_Name
    local Nickname = AgentInfo.Nickname
    local NewText = ""

    for i = 1, #Nickname do
        local TextChar = string.sub(Nickname, i, i)
        if TextChar == " " then
            TextChar = "   "
        end
        NewText = NewText..TextChar.." "
    end

    AgentDataFrame.AgentNickname.Text = NewText--AgentInfo.Nickname

    AgentDataFrame.Playstyle.Role.RoleName.Text = AgentInfo.Role
    AgentDataFrame.Playstyle.Element.ElementName.Text = AgentInfo.Element

    AgentDataFrame.Level.AgentLevel.Text = `Level: {AgentData.Level}/{math.ceil(AgentData.Level / 10) * 10}`
end

return Component
