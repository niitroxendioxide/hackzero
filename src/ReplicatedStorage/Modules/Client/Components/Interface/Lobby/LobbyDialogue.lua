local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client

local Inputs = require(ReplicatedStorage.Modules.Client.Libraries.Inputs)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ScreenUtil = require(ReplicatedStorage.Modules.Shared.Utility.ScreenUtil)
local Signal = require(ReplicatedStorage.Modules.Shared.Utility.Signal)
local UIStates = require(Client.States.Interface)
local NavStates = require(Client.States.Navigation)
local InterfaceClass = require(Client.Classes.Interface)

-- comp def
local Component = InterfaceClass.new("LobbyDialogue", "Dialogue")
local States = {
    InAnimation = false,
    IsOpen = false,
    HasOptions = false,
    DialogueToEnd = Signal.new() :: Signal.ScriptSignal<number>,
}

function WaitForAnimation()
    repeat
        task.wait()    
    until not States.InAnimation
end

function SkipCurrentDialogue(Index: number?)
    States.DialogueToEnd:Fire(Index or 0)
end

function Component:Link(Player: Player): Instance?
    local GUI = Player.PlayerGui
    if not GUI:WaitForChild("LobbyHUD", 12) then
        return
    end

    local HUD = GUI.LobbyHUD:WaitForChild("Screen")
    if not HUD then
        return
    end

    return HUD:WaitForChild("Dialogues")
end

function Component:Init()

    local MainFrame = Component:GetFrame()
    local Box = MainFrame.Main

    Component:BindToStateChange(function(State: boolean)
        MainFrame.Visible = true
        Box.Visible = true
        UIStates:Set("DIALOGUE", State)

        if State then
            NavStates:Set("Movement_Locked", true)
            States.InAnimation = true


            Box.Size = UDim2.fromScale(0.05, .236)
            Box.Position = UDim2.fromScale(0.5, 0.857)

            Effects:Tween(Box, {.15, 'Back'}, {Position = UDim2.fromScale(0.5, 0.85)})
            task.delay(.1, function()
                Effects:Tween(Box, {.25, 'Back'}, {Size = UDim2.fromScale(0.365, .236)})

                task.wait(.15)
                States.InAnimation = false
            end)
        else
            Box.Position = UDim2.fromScale(0.5, 1.2)

            NavStates:Set("Movement_Locked", false)        
        end
    end)

    self:Set(false)

    Inputs:Bind(Enum.UserInputType.MouseButton1, {
        Callback = function()
            if States.IsOpen and not States.InAnimation then
                if States.HasOptions == true then
                    return
                end

                SkipCurrentDialogue(0)
            end
        end,
        Release = false,
    })
end

function Component:OpenDialogue(Name: string, Data: {}): boolean
    if States.IsOpen then
        return false;
    end

    States.IsOpen = true

    local Frame = Component:GetFrame()
    local Box = Frame.Main

    Component:Set(true)

    --
    Box.DialogueText.Text = ''
    Box.CharacterName.Visible = false
    Box.NameFrame.UIStroke.Enabled = false
    Box.NameFrame.Size = UDim2.fromScale(0, 0.179)

    WaitForAnimation()

    Component:ShowName(Name)
    Component:DisplayDialogue(Data)

    return true
end

function Component:CloseDialogue()
    States.IsOpen = false
    Component:Set(false)

    Component:ClearResponses()
    States.DialogueToEnd:DisconnectAll()
end

function Component:ClearResponses()
    States.HasOptions = false;

    const Frame = Component:GetFrame()
    const OptionList = Frame.List;
    for _, Option in OptionList:GetChildren() do
        if Option:IsA('Frame') then
            Option:Destroy();    
        end
    end
end

function Component:DisplayResponses(ResponseList: { string })
    if #ResponseList <= 0 then
        return
    end

    Component:ClearResponses()
    
    const OptionAsset = ReplicatedStorage.Assets.Interface.Lobby.Dialogue.Option
    const Frame = Component:GetFrame()
    const OptionList = Frame.List;

    States.HasOptions = true
    
    for Index, OptText in ResponseList do
        local NewOption = OptionAsset:Clone();
        NewOption.Label.Text = OptText;
        NewOption.Parent = OptionList;
        NewOption.Index.Label.Text = tostring(Index);
        NewOption.Button.MouseButton1Click:Connect(function()
            SkipCurrentDialogue(Index)
        end)
    end
end

function Component:DisplayDialogue(Data: { Text: string, Responses: { string }? })
    assert(typeof(Data) == 'table', "Data passed to DisplayDialogue must be a Table,")
    
    local Frame = Component:GetFrame()
    local Box = Frame.Main

    Box.DialogueText.TextSize = ScreenUtil:GetTextSize(35)
    
    local DialogueText = Data.Text;
    if not DialogueText then
        return;
    end

    task.spawn(function()
        for t = 1, #DialogueText do
            Box.DialogueText.Text = DialogueText:sub(1, t)
            task.wait()
        end
    end)

    if Data.Responses then
        Component:DisplayResponses(Data.Responses)
    else
        Component:ClearResponses()
    end
end

function Component:ShowName(Name: string)
    local Frame = Component:GetFrame()
    local Box = Frame.Main
    
    local Count = math.max(#Name - 11, 0)
    local ExtraSize = Count * 0.03/2 + math.clamp(#Name-11, 0 ,1) * 0.005
    local BaseSize = UDim2.fromScale(0.25 + ExtraSize, 0.179)
    local Rate = 0.5 - (BaseSize.X.Scale - 0.25)

    Effects:Tween(Box.NameFrame, {.25, 'Back'}, {Size = BaseSize})
    Effects:Tween(Box.NameFrame.BG, {.25, 'Quad'}, {TileSize = UDim2.fromScale(Rate, 2)})

    Box.NameFrame.UIStroke.Enabled = true
    Box.CharacterName.Visible = true
    Box.CharacterName.Text = Name
end

function Component:BoxSkipped(fn: () -> ())
    States.DialogueToEnd:Connect(fn)
end

return Component
