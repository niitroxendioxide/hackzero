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
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local UIGroups = require(Client.Libraries.UIGroups)
local Cutscenes = require(Client.Libraries.Cutscenes)
local UIEffects = require(Client.Utility.UIEffects)
local LocalData = require(Client.Libraries.LocalData)
local EffectUtil = require(Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)
local CharacterDatabase = require(Database.Characters)
local DrivesDatabase = require(Database.Drives)
local ArtifactDatabase = require(Database.Artifacts)

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
    __Last_Tab = "",
    __Current_Tab = Scope:Value(""),
    __Current_Selected_Item = '',
    __Current_Selected_Item_Object = nil,
    __Current_Slot_Picked = 0,
    __Current_Item_Filter = "Artifacts",
    __Current_Drive_Selected = nil,
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

    -- This saves a local copy of the agents on client which will later be used by others, this isn't the only script that
    -- calls fetcher, but this makes sure it exists
    local AgentsTable = Fetcher:FetchAgents()
    if #AgentsTable <= 0 then
        Component:Set(false)

        return
    end

    local LastAgent;

    for _, Agent in AgentsTable do
        local AgentName = Agent.Name
        local AgentObj = Assets.Interface.Agents.AgentObj:Clone()

        AgentObj.Btn.MouseButton1Click:Connect(function()
            local ClientData = LocalData:GetAgent(AgentName)
            local Element = UIGroups:GetElementClass("Feeding", "Feeding")

            if Element:IsActive("Agent") then
                return
            end

            Component:SelectAgent(ClientData)
        end)

        AgentObj.Btn.MouseEnter:Connect(function()
            AgentObj.Design.UIStroke.Transparency = 0
            AgentObj.Design.UIStroke.Thickness = 2
        end)

        AgentObj.Btn.MouseLeave:Connect(function()
            AgentObj.Design.UIStroke.Transparency = .75
            AgentObj.Design.UIStroke.Thickness = 1
        end)

        AgentObj.Design.AgentName.Text = AgentName
        AgentObj.Parent = Frame.Agents.Holder

        LastAgent = Agent;
    end

    Component:SelectAgent(LastAgent)
end

local function RequestChangeArtifact()
    local SelectedArtifact = States.__Current_Selected_Item
    local SelectedAgent = States.__Current_Agent.Name

    Network:Fire('UpdateAgent', GameEnum.AgentEvent.UpdateArtifactSlot, {
        SelectedAgent,
        SelectedArtifact
    })
end

local function RequestChangeDrive()
    local SelectedDrive = States.__Current_Drive_Selected
    local SelectedAgent = States.__Current_Agent.Name

    Network:Fire('UpdateAgent', GameEnum.AgentEvent.UpdateDrive, {
        SelectedAgent,
        SelectedDrive
    })
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
    local ReturnHolder: Frame & {Btn: TextButton, UIStroke: UIStroke, UIScale: UIScale} = MainFrame.Return
    local ReturnButton: TextButton = ReturnHolder.Btn
    Component:BindToStateChange(function(State: boolean)
        if State then
            for _, DiffTabs in MainFrame:GetChildren() do
                if DiffTabs.Name ~= 'Agents' and DiffTabs.Name ~= 'TabButtons' then
                    DiffTabs.Visible = false
                end
            end

            UIEffects:Transition('Agents', .75)

            --
            MainFrame.Agents.Visible = true
            MainFrame.TabButtons.Visible = true
            ReturnHolder.Visible = true
            Camera:MarkUsage("AgentMenu")

            CreateAgentIcons()

            States.__Current_Tab:set("Stats")

            --
        else
            for _, DiffTabs in MainFrame:GetChildren() do
                if DiffTabs.Name ~= 'Agents' and DiffTabs.Name ~= 'TabButtons' then
                    DiffTabs.Visible = false
                end
            end

            States.__Current_Agent = nil

            MainFrame.Agents.Visible = false
            MainFrame.TabButtons.Visible = false
            ReturnHolder.Visible = false

            local LobbyMain = UIGroups:GetElementClass('Lobby', 'MainMenu')
            LobbyMain:Set(true)

            --
            Camera:FreeUsage()

            States.__Current_Tab:set("None")
        end
    end)

    ReturnButton.MouseButton1Click:Connect(function()
        Component:Set(false)
    end)

    ReturnButton.MouseEnter:Connect(function()
        ReturnHolder.UIStroke.Color = Color3.new(1, 1, 1)
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1.1})
    end)

    ReturnButton.MouseLeave:Connect(function()
        ReturnHolder.UIStroke.Color = Color3.new()
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1})
    end)

    for _, Button in MainFrame.TabButtons:GetChildren() do
        if not Button:FindFirstChild("Btn") then continue end

        Button.Btn.MouseButton1Click:Connect(function()
            local Element = UIGroups:GetElementClass("Feeding", "Feeding")

            if Element:IsActive("Agent") then
                return
            end

            States.__Current_Tab:set(Button.Name)
        end)
    end

    Scope:Observer(States.__Current_Tab):onChange(function()
        local TabButtons = MainFrame:FindFirstChild("TabButtons")
        local CurrentTab = Component:Peek(States.__Current_Tab)

        for _, Tab in TabButtons:GetChildren() do
            if not Tab:IsA("Frame") then continue end

            if Tab.Name == CurrentTab then
                EffectUtil:Tween(Tab.UIScale, {.25, 'Back', 'Out'}, {Scale = 1.25})
            else
                EffectUtil:Tween(Tab.UIScale, {.25}, {Scale = 1})
            end
        end

        local Frame = MainFrame:FindFirstChild(CurrentTab)

        if Frame or CurrentTab == 'None' then
            if CurrentTab ~= 'None' then
                Frame.Visible = true
            end

            Component:SelectAgent(States.__Current_Agent)

            local StringTabs = {"Items", "Stats", "Skills"}
            for _, SubFrame in MainFrame:GetChildren() do
                if table.find(StringTabs, SubFrame.Name) and SubFrame ~= Frame then
                    SubFrame.Visible = false
                end
            end
        end
    end)


    --
    local StatsFrame = MainFrame.Stats
    local AgentUpgrade = StatsFrame.AgentData.Upgrade
    AgentUpgrade.Button.MouseButton1Click:Connect(function()
        local Element = UIGroups:GetElementClass("Feeding", "Feeding")
        if not States.__Current_Agent then
            return
        end

        Element:ShowAgentFeeding(States.__Current_Agent.Name)
    end)

    --
    local ItemsFrame =  MainFrame.Items
    local ItemDataFrame = ItemsFrame.ItemData
    local DriveDataFrame = ItemsFrame.DriveData

    DriveDataFrame.Equip.Button.MouseButton1Click:Connect(RequestChangeDrive)
    ItemDataFrame.Equip.Button.MouseButton1Click:Connect(RequestChangeArtifact)

    local DriveSelectBtn: TextButton = ItemsFrame.Build.Drive.Select
    local DriveUiScale: UIScale = ItemsFrame.Build.Drive.Design.UIScale
    local Tween: Tween? = nil
    --
    DriveSelectBtn.MouseButton1Click:Connect(function()
        DriveUiScale.Scale = .85
        Tween = EffectUtil:Tween(DriveUiScale, {.3, 'Back'}, {Scale = 1.1})

        if States.__Current_Item_Filter == "Drives" then
            Component:SetItemList(nil)
        else
            Component:SetItemList("Drives")
        end
    end)

    DriveSelectBtn.MouseEnter:Connect(function()
        if Tween then
            Tween:Cancel()
            Tween:Destroy()
        end

        Tween = EffectUtil:Tween(DriveUiScale, {.25, 'Quad'}, {Scale = 1.1})
    end)

    DriveSelectBtn.MouseLeave:Connect(function()
        if Tween then
            Tween:Cancel()
            Tween:Destroy()
        end

        Tween = EffectUtil:Tween(DriveUiScale, {.25, 'Quad'}, {Scale = 1})
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

    local CurrentTab = Component:Peek(States.__Current_Tab)
    if (States.__Last_Tab == CurrentTab) and (States.__Current_Agent ~= nil and States.__Current_Agent.Name == AgentData.Name) then
        return
    end

    local MainFrame = Component:GetFrame()
    if not AgentData then
        return
    end

    States.__Last_Tab = CurrentTab
    States.__Current_Agent = AgentData

    SwitchModel(AgentData.Name)

    if CurrentTab == "Items" then
        Component:ShowArtifacts(AgentData)

        --
        for i = 1, 6 do
            local ArtifactData = AgentData.Artifacts[i]

            Component:UpdateSlotInfo(States.__Current_Agent.Name, i, ArtifactData)
        end

        --
        local Drive = LocalData:GetDriveById(AgentData.Drive)

        Component:UpdateDriveInfo(AgentData.Name, Drive)
    elseif CurrentTab == "Stats" then
        Component:ShowStats(AgentData)
    elseif CurrentTab == "None" then
        print("none?!")
        MainFrame.Stats.Visible = false
        MainFrame.Items.Visible = false
    end
end

--
-- [[ ARTIFACTS & SLOT ]] --
--
local SelectedArtifactThread: thread = nil;
local SelectedDriveThread: thread = nil;

local function SelectArtifact(NewObject: Frame & {Selected: Frame & {UIStroke: UIStroke}, UsedSelected: Frame & {UIStroke: UIStroke}, Used: Frame}, Artifact)
    if SelectedArtifactThread then
        task.cancel(SelectedArtifactThread)
    end

    if SelectedDriveThread then
        task.cancel(SelectedDriveThread)
    end

    if States.__Current_Selected_Item_Object ~= NewObject and States.__Current_Selected_Item_Object ~= nil then
        States.__Current_Selected_Item_Object.Selected.Visible = false
        States.__Current_Selected_Item_Object.UsedSelected.Visible = false
    elseif States.__Current_Selected_Item_Object == NewObject then
        States.__Current_Selected_Item = ''
        States.__Current_Selected_Item_Object = nil

        if NewObject then
            NewObject.Selected.Visible = false
            NewObject.UsedSelected.Visible = false
        end

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

    SelectedArtifactThread = task.spawn(function()
        local Angle = 0

        while true do
            local Delta = task.wait()
            Angle += Delta * 400

            local Thickness = 2 + math.cos(math.rad(Angle)) * 1
            NewObject.Selected.UIStroke.Thickness = Thickness
            NewObject.UsedSelected.UIStroke.Thickness = Thickness
        end
    end)

    --
    Component:ShowArtifactInfo(Artifact.Id)
end

local function SelectDrive(Drive: Types.PlayerDriveData)
    if SelectedDriveThread then
        task.cancel(SelectedDriveThread)
    end

    if SelectedArtifactThread then
        task.cancel(SelectedArtifactThread)
    end

    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Holder = ItemsFrame.List.DrivesList :: ScrollingFrame

    if States.__Current_Drive_Selected == Drive.Id then
        States.__Current_Drive_Selected = nil

        Component:ShowDriveInfo(nil)

        for _, DriveFrame in Holder:GetChildren() do
            if DriveFrame:IsA("Frame") and DriveFrame.Id.Value == Drive.Id then
                DriveFrame.Selected.Visible = false
                DriveFrame.UsedSelected.Visible = false
            end
        end

        return
    elseif States.__Current_Drive_Selected ~= nil and States.__Current_Drive_Selected ~= Drive.Id then
        local PrevId = States.__Current_Drive_Selected

        for _, DriveFrame in Holder:GetChildren() do
            if DriveFrame:IsA("Frame") and DriveFrame.Id.Value == PrevId then
                DriveFrame.Selected.Visible = false
                DriveFrame.UsedSelected.Visible = false
            end
        end
    end

    for _, DriveFrame in Holder:GetChildren() do
        if DriveFrame:IsA("Frame") and DriveFrame.Id.Value == Drive.Id then
            DriveFrame.Selected.Visible = true

            if DriveFrame.Used.Visible then
                DriveFrame.UsedSelected.Visible = true
            end

            SelectedDriveThread = task.spawn(function()
                local Angle = 0

                while true do
                    local Delta = task.wait()
                    Angle += Delta * 400

                    local Thickness = math.max(2 + math.cos(math.rad(Angle)) * 1.75, 1)
                    DriveFrame.Selected.UIStroke.Thickness = Thickness
                    DriveFrame.UsedSelected.UIStroke.Thickness = Thickness
                end
            end)
        end
    end

    States.__Current_Drive_Selected = Drive.Id
    Component:ShowDriveInfo(Drive.Id)
end

function Component:AddArtifact(Artifact: Types.PlayerArtifactData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Holder = ItemsFrame.List.ArtifactsList :: ScrollingFrame

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
        SelectArtifact(NewObject, Artifact)
    end)

    NewObject.Parent = Holder
end

function Component:AddDrive(Drive: Types.PlayerDriveData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Holder = ItemsFrame.List.DrivesList :: ScrollingFrame

    for _, ExistingItem in Holder:GetChildren() do
        if not ExistingItem:IsA("Frame") then continue end
        if ExistingItem.Id.Value == Drive.Id then return end
    end

    --[[]]
    local DriveData = DrivesDatabase:GetDriveData(Drive.Name)

    local NewObject = Assets.Interface.Agents.Items.ListItemDrive:Clone();
    NewObject.Name = Drive.Id
    NewObject.ItemIcon.Image = "rbxassetid://" .. DriveData.IconId
    NewObject.Role.Value = DriveData.Role_Needed
    NewObject.Id.Value = Drive.Id
    NewObject.Used.Visible = Drive.Equipped ~= nil
    NewObject.Visible = true

    NewObject.Button.MouseButton1Click:Connect(function()
        SelectDrive(Drive)
    end)

    NewObject.Parent = Holder
end

function Component:RefreshArtifactInfo(ArtifactId: string)
    if States.__Current_Selected_Item == ArtifactId then
        Component:ShowArtifactInfo(ArtifactId)
    end
end

function Component:RefreshDriveInfo(DriveId: string)
    if States.__Current_Drive_Selected == DriveId then
        Component:ShowDriveInfo(DriveId)
    end
end 

function Component:ShowArtifactInfo(ArtifactId: string?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local DataFrame = ItemsFrame.ItemData

    for _, SubStat in DataFrame.SubStatList:GetChildren() do
        if SubStat:IsA("Frame") then
            SubStat:Destroy()
        end
    end

    if ArtifactId == nil then
        DataFrame.Visible = false;

        return
    end

    local Artifact = LocalData:GetArtifactById(ArtifactId)

    Component:ShowDriveInfo(nil)

    DataFrame.Visible = true;

    DataFrame.ArtifactName.Text = Artifact.Name
    DataFrame.Level.Text = `Level: {Artifact.Level}`

    DataFrame.EquippedData.Visible = Artifact.Equipped ~= nil
    DataFrame.Equip.Label.Text = Artifact.Equipped and 'Switch' or 'Equip'
    if (States.__Current_Agent ~= nil) and Artifact.Equipped == States.__Current_Agent.Name then
        DataFrame.Equip.Label.Text = "Unequip"
    end

    if Artifact.Equipped then
        DataFrame.EquippedData.Text = `Equipped on: <b>{Artifact.Equipped}</b>`
    end

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

function Component:ShowDriveInfo(DriveId: string?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local DataFrame = ItemsFrame.DriveData

    if DriveId == nil then
        DataFrame.Visible = false;

        return
    end

    Component:ShowArtifactInfo(nil)

    DataFrame.Visible = true;

    local Drive = LocalData:GetDriveById(DriveId)
    local DriveData = DrivesDatabase:GetDriveData(Drive.Name)

    DataFrame.ArtifactName.Text = DriveData.Name
    DataFrame.Level.Text = Drive.Level < 60 and `<b>Lvl.</b> {Drive.Level} / 60` or 'MAX.'

    local NextLevelExp = 100
    local Level = Drive.Level
    local Ascensions = Drive.Level // 10

    local MainStatValue = DriveData.Main_Stat.Base + (Level * DriveData.Main_Stat.UpgradePerLevel)
    DataFrame.MainStat.MainName.Text = string.gsub(DriveData.Main_Stat.StatName, '_', ' ')
    DataFrame.MainStat.Value.Text = tostring(MainStatValue)..(if DriveData.Main_Stat.StatName:find('%%') then '%' else '')

    local SubStatValue = DriveData.Advanced_Stat.Base + (Ascensions * DriveData.Advanced_Stat.UpgradePerAscension)
    DataFrame.SubStat.SubName.Text = string.gsub(DriveData.Advanced_Stat.StatName, '_', ' ')
    DataFrame.SubStat.Value.Text = tostring(SubStatValue)..(if DriveData.Advanced_Stat.StatName:find('%%') then '%' else '')

    DataFrame.EquippedData.Visible = Drive.Equipped ~= nil
    DataFrame.Equip.Label.Text = Drive.Equipped and 'Unequip' or 'Equip'
    if Drive.Equipped then
        DataFrame.EquippedData.Text = `Equipped on: <b>{Drive.Equipped}</b>`
    end

    --
    DataFrame.Exp.Fill.Size = UDim2.fromScale(math.clamp(Drive.Experience / NextLevelExp, 0, 1), 1)
    DataFrame.PassiveDesc.Text = DriveData.Passive_Description;
end


function Component:ShowArtifacts(AgentData: Types.ClientAgentData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsFolder = ItemsFrame.Build.Items

    ItemsFrame.Build.UIScale.Scale = 0

    EffectUtil:Tween(ItemsFrame.Build.UIScale, {.3, 'Cubic', 'Out'}, {Scale = 1})

    --
    Component:SelectArtifactSlot(0)

    --
    task.spawn(function()
        local Angle = math.random(0, 360);
        while ItemsFrame.Visible do
            local Delta = task.wait()
            Angle += Delta * 35

            ItemsFrame.Build.RingDecor.Img.Rotation = Angle
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

        local Angle = -math.pi / 3 * i - (math.pi/3)
        local Cos = math.cos(Angle)
        local Sin = math.sin(Angle)

        local NewSlot = Assets.Interface.Agents.Items.ArtifactSlot:Clone()
        NewSlot.Item.Level.Text = "Lvl. "..math.random(1, 99);
        NewSlot.Name = "Slot"..i
        NewSlot.Position = UDim2.fromScale(Cos * .5 + .5, Sin * 0.5 + .5)
        NewSlot.SlotNum.Text = tostring(i)
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
    local ItemsList = ItemsFrame.List.ArtifactsList

    for _, Artifact in ItemsList:GetChildren() do
        if not Artifact:IsA('Frame') then continue end
        Artifact.Visible = Filter(Artifact)
    end

    if typeof(States.__Current_Selected_Item_Object) ~= 'nil' and States.__Current_Selected_Item_Object.Visible == false then
        States.__Current_Selected_Item_Object.Selected.Visible = false
        States.__Current_Selected_Item_Object.UsedSelected.Visible = false
        States.__Current_Selected_Item_Object = nil
        States.__Current_Selected_Item = ''
        Component:ShowArtifactInfo(nil)
    end
end

function Component:SetItemList(Type: string)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsList = ItemsFrame.List

    if Type == nil then
        States.__Current_Item_Filter = nil
        ItemsList.Visible = false

        return
    end

    States.__Current_Item_Filter = Type

    --
    ItemsFrame.DriveData.Visible = false
    ItemsFrame.ItemData.Visible = false
    ItemsList.Visible = true
    ItemsList.TypeLabel.Text = Type;

    for _, List in ItemsList:GetChildren() do
        if List:IsA("ScrollingFrame") and List.Name:match("List") then
            List.Visible = List.Name:match(Type)
        end
    end

    if Type == "Drives" then
        for _, Drive in LocalData:GetDrives() do
            Component:AddDrive(Drive)
        end
    elseif Type == "Artifacts" then
        for _, Artifact in LocalData:GetArtifacts() do
            Component:AddArtifact(Artifact)
        end
    else
        ItemsList.TypeLabel.Text = "?";
    end
end

function Component:SelectArtifactSlot(SlotId: number?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items

    Component:SetItemList("Artifacts")

    local OldSlot = ItemsFrame.Build.Items:FindFirstChild('Slot'..States.__Current_Slot_Picked)
    if OldSlot then
        OldSlot.Outline.Visible = false
    end

    if not(typeof(SlotId) == 'number') or (SlotId < 1) or (SlotId > 6) then
        ItemsFrame.ItemData.Visible = false
        ItemsFrame.DriveData.Visible = false
        Component:SetItemList(nil)
        States.__Current_Slot_Picked = 0

        SelectArtifact(States.__Current_Selected_Item_Object, nil)

        return;
    end

    local NewSlot = ItemsFrame.Build.Items:FindFirstChild('Slot'..SlotId)
    NewSlot.Outline.Visible = true

    States.__Current_Slot_Picked = SlotId

    --
    Component:FilterArtifacts(function(ArtifactFrame)
        return ArtifactFrame.Slot.Value == SlotId
    end)
end

function Component:UpdateSlotInfo(Agent: string, SlotId: number, ArtifactId: string?): ()
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local Artifacts = ItemsFrame.Build

    if (States.__Current_Agent == nil) or (States.__Current_Agent.Name ~= Agent) then
        print(States.__Current_Agent, Agent)
        return
    end

    local SlotFrame = Artifacts.Items:FindFirstChild('Slot'..SlotId)

    if ArtifactId == nil then
        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = false
        end

        SlotFrame.SlotNum.Visible = true
    else
        local Artifact = LocalData:GetArtifactById(ArtifactId)

        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = true
        end

        local TierLetters = {"S", "A", "B", "C"}
        SlotFrame.Item.Tier.Text = TierLetters[Artifact.Tier :: number]
        SlotFrame.Item.Level.Text = `Lvl. {Artifact.Level}`

        SlotFrame.SlotNum.Visible = false
    end
end

function Component:UpdateDriveInfo(Agent: string, Drive: Types.PlayerDriveData)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local DriveFrame = ItemsFrame.Build.Drive

    if (States.__Current_Agent == nil) or (States.__Current_Agent.Name ~= Agent) then
        return
    end

    if Drive == nil then
        DriveFrame.Design.Full.Visible = false
        DriveFrame.Design.Empty.Visible = true

        return
    end

    DriveFrame.Design.Empty.Visible = false
    DriveFrame.Design.Full.Visible = true

    local DriveData = DrivesDatabase:GetDriveData(Drive.Name)

    -- TODO: Also add image changing :sob:
    DriveFrame.Design.Full.Icon.Image = "rbxassetid://" .. (DriveData.IconId or 0)
    DriveFrame.Design.Full.Level.Text = `Lvl. {Drive.Level}`
end

function Component:UpdateArtifact(Artifact: Types.PlayerArtifactData): ()
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsList = ItemsFrame.List.ArtifactsList

    --print(Artifact.Id)

    local ItemObj = ItemsList:FindFirstChild(Artifact.Id)
    if ItemObj then
        ItemObj.Used.Visible = Artifact.Equipped ~= nil

        if ItemObj.Selected.Visible and ItemObj.Used.Visible then
            ItemObj.Selected.Visible = false
            ItemObj.UsedSelected.Visible = true
        end
    end
end

function Component:UpdateDrive(Drive: Types.PlayerDriveData): ()
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local ItemsList = ItemsFrame.List.DrivesList

    --print(Artifact.Id)

    local ItemObj = ItemsList:FindFirstChild(Drive.Id)
    if ItemObj then
        ItemObj.Used.Visible = Drive.Equipped ~= nil

        if ItemObj.Selected.Visible and ItemObj.Used.Visible then
            ItemObj.Selected.Visible = false
            ItemObj.UsedSelected.Visible = true
        end
    end
end

--
-- [[ AGENT STATS ]] --
--
local function CalculateAgentStatBuffs(AgentData: Types.ClientAgentData)
    local AgentStats = CharacterDatabase:GetStatsAtLevel(AgentData.Name, AgentData.Level)
    local StatBuffs = {}

    for _, ArtifactId in AgentData.Artifacts do
        local ArtifactObject = LocalData:GetArtifactById(ArtifactId)
        local Data = ArtifactDatabase:GetArtifactData(ArtifactObject.Name)

        local MainStatName = next(ArtifactObject.Stats.Main_Stat)
        local MainStatValue = ArtifactObject.Stats.Main_Stat[MainStatName]

        local SlotCount = 0
        for _, OtherItemId in AgentData.Artifacts do
            if OtherItemId == ArtifactId then continue end

            local OtherItem = LocalData:GetArtifactById(OtherItemId)
            if OtherItem.Name == ArtifactObject.Name then
                SlotCount += 1
            end
        end

        if SlotCount >= 2 then
            for StatName, StatValue in Data.Piece_Effects.Two_Piece do
                if StatBuffs[StatName] == nil then
                    StatBuffs[StatName] = 0
                end

                StatBuffs[StatName] += StatValue
            end

            if SlotCount >= 4 then
                for StatName, StatValue in Data.Piece_Effects.Two_Piece do
                    if StatBuffs[StatName] == nil then
                        StatBuffs[StatName] = 0
                    end

                    StatBuffs[StatName] += StatValue
                end
            end
        end

        if StatBuffs[MainStatName] == nil then
            StatBuffs[MainStatName] = 0
        end

        StatBuffs[MainStatName] += MainStatValue

        --
        for SubName, SubValue in ArtifactObject.Stats.Sub_Stats do
            if StatBuffs[SubName] == nil then
                StatBuffs[SubName] = 0
            end

            StatBuffs[SubName] += SubValue
        end
    end

    local AgentDrive = AgentData.Drive ~= nil and LocalData:GetDriveById(AgentData.Drive)
    if AgentDrive then
        local Level = AgentDrive.Level
        local DriveData = DrivesDatabase:GetDriveData(AgentDrive.Name)
        local MainStatName = DriveData.Main_Stat.StatName
        local MainStatValue = DriveData.Main_Stat.Base + (DriveData.Main_Stat.UpgradePerLevel) * Level

        if StatBuffs[MainStatName] == nil then
            StatBuffs[MainStatName] = 0
        end

        StatBuffs[MainStatName] += MainStatValue

        local SubStatName = DriveData.Advanced_Stat.StatName
        local SubStatValue = DriveData.Advanced_Stat.Base + (DriveData.Advanced_Stat.UpgradePerAscension) * (Level // 10)

        if StatBuffs[SubStatName] == nil then
            StatBuffs[SubStatName] = 0
        end

        StatBuffs[SubStatName] += SubStatValue
    end

    for StatBuffName, StatBuffValue in StatBuffs do
        if string.match(StatBuffName, "%%") then
            local StatRaw = string.gsub(StatBuffName, "%%", "")

            local AddedPercentBoost = AgentStats[StatRaw] * (StatBuffValue / 100)
            if not StatBuffs[StatRaw] then
                StatBuffs[StatRaw] = 0
            end

            StatBuffs[StatRaw] += AddedPercentBoost
            StatBuffs[StatBuffName] = nil
        end
    end

    return StatBuffs
end

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

    local StatBuffs = CalculateAgentStatBuffs(AgentData)

    local AddPercent = {"Critical_Damage", "Critical_Rate", "Pen_Ratio"}
    local Ignored = {"Penetration", "Jog_Speed", "Walk_Speed", "Sprint_Speed"}
    for Stat, Value in AgentStats do
        if table.find(Ignored, Stat) then continue end

        local ShownValue = Value
        if StatBuffs[Stat] then
            ShownValue += StatBuffs[Stat]
        end

        local NewFrame = Assets.Interface.Agents.Stats.Stat:Clone()
        NewFrame.StatName.Text = string.gsub(Stat, "_", " ")
        NewFrame.StatValue.Text = ShownValue .. (table.find(AddPercent, Stat) and '%' or '')
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
