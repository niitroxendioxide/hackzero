local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client

local Navigation = require(ReplicatedStorage.Modules.Client.States.Navigation)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local ComponentClass = require(Client.Classes.Interface)
local UIGroups = require(Client.Libraries.UIGroups)
local Camera = require(Client.Libraries.Camera)
local Animation = require(Client.Libraries.Animation)

local Interactions = ComponentClass.new("Interactions", "Interactions")
:: Types.UIComponent & {GetButton: (Name: string) -> (TextButton), SetButton: (Name: string, State: boolean) -> ()}


local States = {
    Active = false
}
local LastClick = os.clock()

function SetNPCAnimPlaying(Track: string): ()
    if Track == 'Inactive' and (States.Active == true) then
        
        return
    end

    local AnimsFolder = ReplicatedStorage.Assets.Animations.Lobby.MissionDesk
    local Character = workspace.World.Map.Design.NPCS:FindFirstChild('MissionNPCRig')

    if States.CurrentTrackThread then
        task.cancel(States.CurrentTrackThread)
    end

    if States.CurrentTrack ~= nil then
        States.CurrentTrack:Stop(0.3)
    end

    if Track == 'Active' then
        States.CurrentTrack = Animation:Play(Character, AnimsFolder.AttentionToWait)

        States.CurrentTrackThread = task.delay(0.533, function()
            States.CurrentTrack:Stop(.2)
            States.CurrentTrack = Animation:Play(Character, AnimsFolder.WaitingPose)
        end)
    elseif Track == 'Inactive' then
        States.CurrentTrack = Animation:Play(Character, AnimsFolder.Idle)
    elseif Track == 'Attention' then
        States.CurrentTrack = Animation:Play(Character, AnimsFolder.Attention)

        States.CurrentTrackThread = task.delay(0.567, function()
            States.CurrentTrack:Stop(.35)
            States.CurrentTrack = Animation:Play(Character, AnimsFolder.AttentionIdle)
        end)
    end
end

function AnimateTabHovers(Tab: Frame)
    
    
    Tab.MouseEnter:Connect(function()
        Effects:Tween(Tab.UIShadow, { 0.5, 'Quart' }, {Color = Color3.new(0.235294, 0.235294, 0.235294)})
        Effects:Tween(Tab.OuterStroke, { 0.3, 'Quart' }, {Color = Color3.new(0.294118, 0.294118, 0.294118)})
    end)

    Tab.MouseLeave:Connect(function()
        Effects:Tween(Tab.UIShadow, { 0.5, 'Quart' }, {Color = Color3.new(0, 0, 0)})
        Effects:Tween(Tab.OuterStroke, { 0.3, 'Quart' }, {Color = Color3.new(0, 0, 0)})
    end)
    
end

--
function Interactions:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end

	local Main = HUD:FindFirstChild("Interactions", true)

    return Main
end

function Interactions:Init()
    ScreenUtil:AdjustStrokes(self:GetFrame())

    local FrameTab = self:GetFrame().MainFrame

    local CreateTab = FrameTab:FindFirstChild('CreateTab') :: Frame
    local SearchTab = FrameTab:FindFirstChild('SearchTab') :: Frame
    local ReturnBtn = FrameTab:FindFirstChild('Return') :: Frame

    AnimateTabHovers(CreateTab)
    AnimateTabHovers(SearchTab)

    CreateTab.CreateButton.Button.MouseButton1Click:Connect(function()
        if (os.clock() - LastClick) < 1/4 then
            return
        end

        LastClick = os.clock()
        local PartyUI = UIGroups:GetElementClass("Lobby", "NewPartyComponent")
        PartyUI:CreateParty()
        self:Set(false)
    end)

    SearchTab.SearchButton.Button.MouseButton1Click:Connect(function()
        if (os.clock() - LastClick) < 1/4 then
            return
        end
        
        LastClick = os.clock()
        local PartiesBrowserUI = UIGroups:GetElementClass("Lobby", "Parties")

        PartiesBrowserUI:LoadParties()
         self:Set(false)
    end)

    ReturnBtn.Btn.MouseButton1Click:Connect(function()
        self:Set(false)

        local MainMenuUI = UIGroups:GetElementClass("Lobby", "MainMenu")
        if MainMenuUI then
            MainMenuUI:Set(true, true)
        end
    end)

    ReturnBtn.MouseEnter:Connect(function()
		Effects:Tween(ReturnBtn.ThinStroke, {0.3, 'Quart'}, {Thickness = 0.04, Color = Color3.fromRGB(245, 47, 47)})
		Effects:Tween(ReturnBtn.UIShadow, {0.5, 'Quart'}, {Transparency = 0.75})
	end)

	ReturnBtn.MouseLeave:Connect(function()
		Effects:Tween(ReturnBtn.ThinStroke, {0.3, 'Quart'}, {Thickness = 0.05, Color = Color3.fromRGB(152, 29, 29)})
		Effects:Tween(ReturnBtn.UIShadow, {0.5, 'Quart'}, {Transparency = 1})
	end)

    SetNPCAnimPlaying("Inactive", true)

    local CleanupObjects = {}
    local Positions = { [true] = UDim2.fromScale(.825, .5), [false] = UDim2.fromScale(1.25, 0.5) }
    self:BindToStateChange(function(State: boolean)
        self:GetFrame().Visible = true
        States.Active = State

        for _, TweenOrThread in CleanupObjects do
            if typeof(TweenOrThread) == 'thread' then
                task.cancel(TweenOrThread)
            else
                TweenOrThread:Cancel()
            end
        end

        if State then
            SetNPCAnimPlaying("Active")
            Camera:MarkUsage("ChaosControl")

            table.insert(CleanupObjects, Effects:Tween(workspace.CurrentCamera, { 0.45, 'Quint' }, { CFrame = workspace.World.LobbyCutscenes.MissionDesk.Camera.CFrame }))
            table.insert(CleanupObjects, Effects:Tween(workspace.CurrentCamera, { 0.6, 'Back' }, { FieldOfView = 60 }))
            Navigation:Set("Movement_Locked", true)
        else
            SetNPCAnimPlaying("Inactive")
            Camera:FreeUsage()
            Navigation:Set("Movement_Locked", false)
        end

        Effects:Tween(FrameTab, { 0.35, 'Quart' }, {Position = Positions[State]})
    end)
end

function Interactions:WaitForClose(Handler: () -> ())
    Interactions.__FiringSignal = Handler
end

function Interactions:FireLeaveSignal()
    if typeof(Interactions.__FiringSignal) == "function" then
        task.defer(Interactions.__FiringSignal)
    end
end

function Interactions:ShownPromptInteraction()
    return SetNPCAnimPlaying("Attention")
end

function Interactions:HiddenPromptInteraction()
    return SetNPCAnimPlaying("Inactive")
end

return Interactions