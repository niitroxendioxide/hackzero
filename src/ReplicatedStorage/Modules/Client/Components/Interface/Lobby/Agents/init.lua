local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets
local World = workspace:FindFirstChild("World")


local Effects = require(ReplicatedStorage.Modules.Client.Libraries.Effects)
local UIUtils = require(ReplicatedStorage.Modules.Client.Libraries.UIUtils)
local ItemNameGen = require(ReplicatedStorage.Modules.Client.Utility.ItemNameGen)
local Artifacts = require(ReplicatedStorage.Modules.Shared.Database.Artifacts)
local Icons = require(ReplicatedStorage.Modules.Shared.Database.Icons)
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Math = require(ReplicatedStorage.Modules.Shared.Utility.Math)
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
local SkillsSubModule = require(script.Skills)
local AscensionsSubModule = require(script.Ascensions)

--
export type FilterFunction = (Artifact: Frame & {Slot: NumberValue, Type: StringValue}) -> (boolean)
local RoomLocations = World:FindFirstChild("LobbyCutscenes")
if RoomLocations then
    RoomLocations = RoomLocations:FindFirstChild("AgentsRoom").Used
end

--
local ModelAnims = require(script.Animations)
local Component = ComponentClass.new(script.Name, 'Lobby') :: Types.UIComponent & {FilterArtifacts: (self: Types.UIComponent, FilterFunction) -> ()}
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
    __Model_Base_CF = nil,
    __Rotation_Model = 0,
}

--
local function SwitchModel(Name: string)
    local PlayEffect = false
    local CharacterPlace = World:FindFirstChild("LobbyCutscenes"):FindFirstChild("AgentsRoom")
    if States.__Current_Model ~= nil and States.__Current_Model.Name ~= Name then
        PlayEffect = true
        States.__Rotation_Model = 0
    end
    
    if States.__Current_Model then
        States.__Current_Model:Destroy()
    end
    
    local AgentData = CharacterDatabase:GetCharacterData(Name, true)

    local CharacterModel = Assets.Characters.Agents:FindFirstChild(Name)
    if AgentData.Model and not CharacterModel then
        local Dir, Model = table.unpack(string.split(AgentData.Model, '/')) 
        CharacterModel = Assets.Characters[Dir]:FindFirstChild(Model) or Assets.Characters.Agents.Template;
    end

    if CharacterModel then
        local PivotCFrame = RoomLocations.CharacterPlace.CFrame
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Include
        Params.FilterDescendantsInstances = {CharacterPlace.Grass}

        local Ground = Workspace:Raycast(PivotCFrame.Position, vector.create(0, -10), Params)
        if not Ground then
            return
        end
        
        local Appearance = CharacterDatabase:GetAppearanceData(Name)
        States.__Model_Base_CF = CFrame.lookAlong(Ground.Position + vector.create(0, Appearance.Height), PivotCFrame.LookVector)

        local Cloned = CharacterModel:Clone()
        Cloned.PrimaryPart.Anchored = true;
        Cloned:PivotTo(States.__Model_Base_CF)
        Cloned.Parent = World.Entities.Appearances

        States.__Current_Model = Cloned;
        if PlayEffect then 
            Effects:Play("CharSwitch", Cloned)
        end
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
        local AgentData = CharacterDatabase:GetCharacterData(AgentName, true)
        local AgentObj = Assets.Interface.Agents.AgentObj:Clone()

        AgentObj.Btn.MouseButton1Click:Connect(function()
            AgentObj.Design.UIScale.Scale = 0.85;
            EffectUtil:Tween(AgentObj.Design.UIScale, { 0.25, 'Back' }, {Scale = 1})
            
            local ClientData = LocalData:GetAgent(AgentName)
            local Element = UIGroups:GetElementClass("Feeding", "Feeding")

            if Element:IsActive("Agent") then
                return
            end

            Component:SelectAgent(ClientData)
        end)

        AgentObj.Btn.MouseEnter:Connect(function()
            EffectUtil:Tween(AgentObj.Design.InnerStroke, { 0.25, 'Quad' }, {Color = Color3.new(1, 1, 1)})
        end)

        AgentObj.Btn.MouseLeave:Connect(function()
            EffectUtil:Tween(AgentObj.Design.InnerStroke, { 0.25, 'Quad' }, {Color = Color3.fromRGB(47, 47, 47)})
        end)

        ---
        local AgentModel = Assets.Characters.Agents:FindFirstChild(AgentName) or Assets.Characters.Agents.Template
        if AgentData.Model then
            local Dir, ModelName = table.unpack(string.split(AgentData.Model, "/"))
            AgentModel = Assets.Characters:FindFirstChild(Dir):FindFirstChild(ModelName)
            if AgentModel == nil then
                AgentModel = Assets.Characters.Agents.Template
            end
        end

        local ClonedAgentModel = AgentModel:Clone();
        ClonedAgentModel:PivotTo(CFrame.new());
        ClonedAgentModel.Parent = AgentObj.Design.Viewport.WorldModel;

        local NewCamera = Instance.new('Camera')
        NewCamera.CFrame = CFrame.new(0, 1.75, -180) * CFrame.Angles(0, math.pi, 0)
        NewCamera.FieldOfView = 1
        NewCamera.Parent = AgentObj.Design.Viewport

        AgentObj.Design.Viewport.CurrentCamera = NewCamera

        if AgentData.IconGlowColor ~= nil then
            AgentObj.Design.Glow.BackgroundColor3 = AgentData.IconGlowColor::Color3 
        end

        AgentObj.Design.AgentName.Text = AgentData.Display_Name
        AgentObj.Parent = Frame.Agents.Holder

        LastAgent = Agent;
    end

    Component:SelectAgent(LastAgent)
end

local function RequestChangeArtifact()
    local SelectedArtifact = States.__Current_Selected_Item
    local SelectedAgent = States.__Current_Agent.Name

    Network:Fire('UpdateAgent', GameEnum.BuildEvent.UpdateArtifactSlot, {
        SelectedAgent,
        SelectedArtifact
    })
end

local function RequestChangeDrive()
    local SelectedDrive = States.__Current_Drive_Selected
    local SelectedAgent = States.__Current_Agent.Name

    Network:Fire('UpdateAgent', GameEnum.BuildEvent.UpdateDrive, {
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
    RunService.Heartbeat:Connect(function(Delta: number)  
        if not States.__Current_Model or not States.__Model_Base_CF then
            return
        end

        local Pivot = States.__Model_Base_CF * CFrame.Angles(0, math.rad(States.__Rotation_Model), 0)
        States.__Current_Model:PivotTo(States.__Current_Model:GetPivot():Lerp(Pivot, Delta * 20))
    end)

    UserInputService.InputBegan:Connect(function(Obj: InputObject, a1: boolean)  
        if a1 then 
            return 
        end

        if Obj.UserInputType == Enum.UserInputType.MouseButton1 then
           if Component:Peek(States.__Current_Tab) == 'None' or Component:Peek(States.__Current_Tab) == "" then
                return
           end
            
           while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                local _TimeDelta = task.wait()

                local MouseDelta = UserInputService:GetMouseDelta();
                States.__Rotation_Model += MouseDelta.X;
                
           end

           UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

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
            local LobbyMain = UIGroups:GetElementClass('Lobby', 'MainMenu')
            LobbyMain:Set(true)

            task.wait(.25)

            for _, DiffTabs in MainFrame:GetChildren() do
                if DiffTabs.Name ~= 'Agents' and DiffTabs.Name ~= 'TabButtons' then
                    DiffTabs.Visible = false
                end
            end

            States.__Current_Agent = nil

            MainFrame.Agents.Visible = false
            MainFrame.TabButtons.Visible = false
            ReturnHolder.Visible = false

            --
            Camera:FreeUsage()

            States.__Current_Tab:set("None")
        end
    end)

    ReturnButton.MouseButton1Click:Connect(function()
        Component:Set(false)
    end)

    ReturnButton.MouseEnter:Connect(function()
        ReturnHolder.OuterStroke.Color = Color3.new(1, 1, 1)
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1.1})
    end)

    ReturnButton.MouseLeave:Connect(function()
        ReturnHolder.OuterStroke.Color = Color3.new()
        EffectUtil:Tween(ReturnHolder.UIScale, {.25}, {Scale = 1})
    end)

    local IdToNames = {'Stats', 'Skills', 'Items', 'Ascensions'}
    for _, Button in MainFrame.TabButtons:GetChildren() do
        if not Button:FindFirstChild("Btn") then continue end

        Button.Btn.MouseButton1Click:Connect(function()
            local Element = UIGroups:GetElementClass("Feeding", "Feeding")

            if Element:IsActive("Agent") then
                return
            end

            local Id = tonumber(Button.Name, 10)
            if not Id then return end

            States.__Current_Tab:set(IdToNames[Id])
        end)
    end

    Scope:Observer(States.__Current_Tab):onChange(function()
        local TabButtons = MainFrame:FindFirstChild("TabButtons")
        local CurrentTab = Component:Peek(States.__Current_Tab)

        for _, Tab in TabButtons:GetChildren() do
            local Id = tonumber(Tab.Name, 10)
            if not Tab:IsA("Frame") or not Id then continue end

            if IdToNames[Id] == CurrentTab then
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

            for _, SubFrame in MainFrame:GetChildren() do
                if table.find(IdToNames, SubFrame.Name) and SubFrame ~= Frame then
                    SubFrame.Visible = false
                end
            end
        end
    end)


    --
    local StatsFrame = MainFrame.Stats
    local AgentUpgrade = StatsFrame.AgentData.Upgrade
    local GlowTween = nil;

    AgentUpgrade.Button.MouseEnter:Connect(function()
        if GlowTween then
            GlowTween:Cancel();
        end

        AgentUpgrade.Glow.UIGradient.Offset = Vector2.new(-0.8, 0)
        GlowTween = EffectUtil:Tween(AgentUpgrade.Glow.UIGradient, { 0.4, 'Quad' }, {Offset = Vector2.new(0.8, 0)})

        EffectUtil:Tween(AgentUpgrade.UIStroke, { 0.4, 'Quad' }, {Color = Color3.fromRGB(74, 223, 0), Thickness = 0.07})
        EffectUtil:Tween(AgentUpgrade.Bg, { 0.4, 'Quad' }, {ImageTransparency = 0.4})
        EffectUtil:Tween(AgentUpgrade.UIScale, { 0.3, 'Quad' }, {Scale = 1.04})
    end)

    AgentUpgrade.Button.MouseLeave:Connect(function()
        EffectUtil:Tween(AgentUpgrade.UIStroke, { 0.4, 'Quad' }, {Color = Color3.fromRGB(45, 141, 0), Thickness = 0.05})
        EffectUtil:Tween(AgentUpgrade.Bg, { 0.4, 'Quad' }, {ImageTransparency = 0.85})
        EffectUtil:Tween(AgentUpgrade.UIScale, { 0.3, 'Quad' }, {Scale = 1})
    end)

    AgentUpgrade.Button.MouseButton1Click:Connect(function()
        AgentUpgrade.UIScale.Scale = 0.8
        EffectUtil:Tween(AgentUpgrade.UIScale, { 0.25, 'Back' }, {Scale = 1})

        local Element = UIGroups:GetElementClass("Feeding", "Feeding")
        if not States.__Current_Agent then
            return
        end

        if States.__Current_Agent.Level >= Statics.Max_Character_Level then
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

function Component:RefreshInformation(LevelUp: boolean)
    if States.__Last_Tab == 'Stats' then
        Component:ShowStats(States.__Current_Agent)

        local Element = UIGroups:GetElementClass("Feeding", "Feeding")

        if LevelUp then
            Effects:Play("CharSwitch", States.__Current_Model, true)
        end

        Element:UpdateProgressBar()
    end
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

    if #CurrentTab > 1 then
        ModelAnims:PlayAnim(States.__Current_Model, CurrentTab, AgentData.Name)
    end

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
    elseif CurrentTab == 'Skills' then
        Component:ShowSkills(AgentData)
    elseif CurrentTab == 'Ascensions' then
        Component:ShowAscensions(AgentData)
    elseif CurrentTab == "None" then
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

            local Thickness = 0.045 - math.cos(math.rad(Angle)) * 0.015
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

    local DbArtifact = Artifacts:Get(Artifact.Name)
    local NewObject = Assets.Interface.Agents.Items.ListItemArtifact:Clone()
    NewObject.Name = Artifact.Id
    NewObject.Id.Value = Artifact.Id
    NewObject.Slot.Value = Artifact.Slot
    NewObject.Type.Value = Artifact.Name
    NewObject.Used.Visible = Artifact.Equipped ~= nil
    NewObject.Button.MouseButton1Click:Connect(function()
        SelectArtifact(NewObject, Artifact)
    end)

    local HasModel = UIUtils:CreateArtifactModel(Artifact.Name, Artifact.Slot, NewObject.Viewport, Artifact.Id)
    if not HasModel then
        NewObject.ItemName.Text = DbArtifact.Name or Artifact.Name
        NewObject.ItemName.Visible = true
    end

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
        EffectUtil:Tween(DataFrame, {.15, 'Cubic', 'In'}, {Position = UDim2.fromScale(0.4, 0.548)})

        return
    end

    local Artifact = LocalData:GetArtifactById(ArtifactId)

    if not DataFrame.Visible then
        DataFrame.Position = UDim2.fromScale(0.4, 0.548)
        DataFrame.Visible = true
    end

    EffectUtil:Tween(DataFrame, {.2, 'Cubic'}, {Position = UDim2.fromScale(1.25, 0.548)})

    Component:ShowDriveInfo(nil)

    DataFrame.ArtifactName.Text = Artifact.Name
    DataFrame.Level.Text = `Level: {Artifact.Level}`
    DataFrame.ItemName.Text = ItemNameGen(ArtifactId);

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
    local MainStatValue = Artifact.Stats.Main_Stat[MainStatName]
    local Rounded = math.round(MainStatValue * 10) / 10

    local StatText = (Rounded % 1 == 0)
        and string.format("%d", Rounded)
        or string.format("%.1f", Rounded)

    DataFrame.MainStat.Value.Text = StatText .. (if MainStatName:find('%%') then '%' else '')

    for StatName, TotalUpgrades in Artifact.Stats.Sub_Stats do
        local PerUpg = Statics.SubStatIncreases[StatName]
        local Tick = PerUpg and PerUpg[Artifact.Tier] or 0

        print(PerUpg, TotalUpgrades, StatName)
        local Value = Tick * TotalUpgrades
        local NewAsset = Assets.Interface.Agents.Items.ArtifactSubStat:Clone()
        NewAsset.SubName.Text = string.gsub(StatName, '_', " ")
        NewAsset.Value.Text = Value
        NewAsset.Amount.Visible = true
        NewAsset.Amount.Text = '+'..TotalUpgrades
        NewAsset.Parent = DataFrame.SubStatList
    end
end

function Component:ShowDriveInfo(DriveId: string?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items
    local DataFrame = ItemsFrame.DriveData

    if DriveId == nil then
        EffectUtil:Tween(DataFrame, {.15, 'Cubic', 'In'}, {Position = UDim2.fromScale(0.4, 0.548)})

        return
    end

    Component:ShowArtifactInfo(nil)

    if not DataFrame.Visible then
        DataFrame.Position = UDim2.fromScale(0.4, 0.548)
        DataFrame.Visible = true
    end

    EffectUtil:Tween(DataFrame, {.2, 'Cubic'}, {Position = UDim2.fromScale(1.25, 0.548)})

    local Drive = LocalData:GetDriveById(DriveId)
    local DriveData = DrivesDatabase:GetDriveData(Drive.Name)

    DataFrame.ItemName.Text = ItemNameGen(DriveId);
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
            Tween = EffectUtil:Tween(NewSlot.UIScale, {.3, 'Back'}, {Scale = 1.25})

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

            Tween = EffectUtil:Tween(NewSlot.UIScale, {.25, 'Quad'}, {Scale = 1.25})
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

local CircleSelectedArtifactThread: thread? = nil;
function Component:SelectArtifactSlot(SlotId: number?)
    local MainFrame = Component:GetFrame()
    local ItemsFrame =  MainFrame.Items

    if CircleSelectedArtifactThread then
        task.cancel(CircleSelectedArtifactThread)
    end

    Component:SetItemList("Artifacts")

    local OldSlot = ItemsFrame.Build.Items:FindFirstChild('Slot'..States.__Current_Slot_Picked)
    if OldSlot then
        OldSlot.UIStroke.Enabled = true
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
    NewSlot.UIStroke.Enabled = false
    NewSlot.Outline.Visible = true

    States.__Current_Slot_Picked = SlotId

    CircleSelectedArtifactThread = task.spawn(function()
        local Angle = 0;
        while true do
            Angle += task.wait() * math.pi;

            NewSlot.Outline.UIStroke.Thickness = 0.08 + math.cos(Angle) * 0.015
        end
    end)

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
        return
    end

    local SlotFrame = Artifacts.Items:FindFirstChild('Slot'..SlotId)

    if ArtifactId == nil then
        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = false
        end

        SlotFrame.Item.Viewport.WorldModel:ClearAllChildren();
        SlotFrame.SlotNum.Visible = true
    else
        local Artifact = LocalData:GetArtifactById(ArtifactId)

        for _, Object in SlotFrame.Item:GetChildren() do
            Object.Visible = true
        end

        local TierLetters = {"S", "A", "B", "C"}
        SlotFrame.Item.Tier.Text = TierLetters[Artifact.Tier :: number]
        SlotFrame.Item.Level.Text = `Lvl. {Artifact.Level}`

        local HasModel = UIUtils:CreateArtifactModel(Artifact.Name, SlotId, SlotFrame.Item.Viewport, ArtifactId)
        SlotFrame.Item.ItemIcon.Visible = not HasModel

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
    local StatBuffs = {}

    local Artifacts = {}
    for _, ArtifactId in AgentData.Artifacts do
        local ArtifactObject = LocalData:GetArtifactById(ArtifactId)

        table.insert(Artifacts, ArtifactObject)
    end

    local AgentDrive = AgentData.Drive ~= nil and LocalData:GetDriveById(AgentData.Drive)
    StatBuffs = Math:CalculateStatsForAgent(AgentData.Name, AgentData.Level, AgentDrive, Artifacts)

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
    local Ignored = {"Penetration", "Jog_Speed", "Walk_Speed", "Sprint_Speed", "Speed"}
    local RenamedStat = {
        ['Health'] = "HP",
        ['Defense'] = "DEF",
        ['Attack'] = "ATK",
        ["Critical_Rate"] = "CRIT Rate",
        ["Critical_Damage"] = "CRIT DMG",
        ["Pen_Ratio"] = "PEN%"
    }
    local Weights = {['Health'] = 0, ['Attack'] = 1, ['Defense'] = 2, ['Daze'] = 3, ['Critical_Rate'] = 4, ['Critical_Damage'] = 5}

    local k = 0;
    for Stat, Value in AgentStats do
        k += 1
        if table.find(Ignored, Stat) then continue end

        local ShownValue = Value
        if StatBuffs[Stat] then
            ShownValue += StatBuffs[Stat]
        end

        local NewFrame = Assets.Interface.Agents.Stats.Stat:Clone()
        NewFrame.StatName.Text = RenamedStat[Stat] or (string.gsub(Stat, "_", " "))
        NewFrame.LayoutOrder = Weights[Stat] or 6
        NewFrame.UIScale.Scale = 0
        NewFrame.StatValue.Text = math.floor(ShownValue * 10) / 10 .. (table.find(AddPercent, Stat) and '%' or '')
        if Stat == 'Energy_Regeneration' then
            NewFrame.StatValue.Text = NewFrame.StatValue.Text.."/s"
        end

        if AgentInfo.ImportantStats and table.find(AgentInfo.ImportantStats, Stat) then
            NewFrame.StatName.TextColor3 = Color3.fromRGB(255, 136, 0)
            NewFrame.StatName.UIStroke.Color = Color3.fromRGB(135, 90, 0)

            NewFrame.StatValue.TextColor3 = Color3.fromRGB(255, 173, 57)
            NewFrame.StatValue.UIStroke.Color = Color3.fromRGB(135, 90, 0)
            NewFrame.StatValue.UIStroke.UIGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 157, 0)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            }

            NewFrame.UIStroke.Color = Color3.fromRGB(70, 44, 0)
            NewFrame.BackgroundColor3 = Color3.fromRGB(56, 48, 37)
        end

        NewFrame.Parent = Frame.Stats.ValuesArea.Holder

        task.delay((NewFrame.LayoutOrder) * 0.04, function()
            EffectUtil:Tween(NewFrame.UIScale, {0.15, 'Back'}, {Scale = 1})
        end)
    end

    --
    local AgentDataFrame = Frame.Stats.AgentData
    AgentDataFrame.AgentFaction.Text = AgentInfo.Faction
    AgentDataFrame.AgentFullName.Text = AgentInfo.Display_Name
    local Nickname = AgentInfo.Nickname
    local NewText = ""

    AgentDataFrame.Level.AgentLevel.Text = `Lvl. {AgentData.Level}`

    for i = 1, #Nickname do
        local TextChar = string.sub(Nickname, i, i)
        if TextChar == " " then
            TextChar = "   "
        end
        NewText = NewText..TextChar.." "
    end

    AgentDataFrame.AgentNickname.Text = NewText--AgentInfo.Nickname

    local RoleIcon = Icons.Roles[AgentInfo.Role]
    local ElementIcon = Icons.Elements[AgentInfo.Element]

    AgentDataFrame.Playstyle.Role.RoleName.Text = AgentInfo.Role
    AgentDataFrame.Playstyle.Role.Icon.Image = RoleIcon or Icons.Roles.Affliction
    AgentDataFrame.Playstyle.Element.Icon.Image = ElementIcon or Icons.Elements.Water
    AgentDataFrame.AscensionCount.Text = AgentData.Ascensions
    
    local Percent = AgentData.Experience / Statics.Experience_For_Level(AgentData.Level + 1)
    EffectUtil:Tween(AgentDataFrame.Level.FillHolder.Fill, { .25, 'Quad' }, { Size = UDim2.fromScale(math.clamp(Percent * 0.9, 0, 0.9), 1) })
    EffectUtil:Tween(AgentDataFrame.Level.FillHolder.Strokes, { .25, 'Quad' }, { Size = UDim2.fromScale(math.clamp(Percent * 0.9, 0, 0.9), 1) })

end

function Component:DisplayDodges(Current: number, Max: number)
    local MainFrame = self:GetFrame()
    local SkillsFrame = MainFrame.Skills

    SkillsSubModule:DisplayDodgeCount(SkillsFrame, Current, Max)
end

function Component:ShowSkills()
    local MainFrame = self:GetFrame()
    local SkillsFrame = MainFrame.Skills

    Camera:TweenTo(RoomLocations.SkillsTab.CFrame, {.6, 'Cubic'})

    SkillsSubModule:UpdateSkills(SkillsFrame, States.__Current_Agent.Name)
end

function Component:RefreshSkills()
    local MainFrame = self:GetFrame()
    local SkillsFrame = MainFrame.Skills

    SkillsSubModule:UpdateSkillLevels(SkillsFrame, States.__Current_Agent.Name)
end

function Component:ShowAscensions()
    local MainFrame = self:GetFrame()
    local AscensionsFrame = MainFrame.Ascensions

    Camera:TweenTo(RoomLocations.AscensionsTab.CFrame, {.6, 'Cubic'})

    AscensionsSubModule:UpdateAscensionInfo(AscensionsFrame, States.__Current_Agent.Name)
end

function Component:RefreshAscensions()
    local MainFrame = self:GetFrame()
    local AscensionsFrame = MainFrame.Ascensions

    AscensionsSubModule:RefreshAscensionInfo(AscensionsFrame, States.__Current_Agent.Name)
end

return Component