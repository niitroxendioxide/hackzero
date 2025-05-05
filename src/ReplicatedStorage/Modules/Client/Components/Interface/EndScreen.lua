local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(ReplicatedStorage.Modules.Shared.Types)
local ComponentClass = require(Client.Classes.Interface)
local UIGroups = require(Client.Libraries.UIGroups)
local EffectUtil = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)
local Network = require(Shared.Network)

local EndScreen = ComponentClass.new("EndScreen", "END")
:: Types.UIComponent & Types.UIGetSetButton

-- testing? idk bro

local Disabled = {}
local HoverThreads = {}
local ColorInfo = {
    ["B"] = {Color3.fromRGB(30, 188, 255), Color3.fromRGB(21, 115, 255)},
    ["A"] = {Color3.fromRGB(156, 117, 255), Color3.fromRGB(35, 46, 255)},
    ["S"] = {Color3.fromRGB(255, 209, 43), Color3.fromRGB(255, 74, 74)},
}

--
local function LightingEffects(State: boolean)
    local ColorCorrection = Lighting:FindFirstChild("ENDSCREENCC") or Instance.new("ColorCorrectionEffect")
    ColorCorrection.Parent = Lighting
    ColorCorrection.Name = "ENDSCREENCC"

    print("Testing one thing")

    local Blur = Lighting:FindFirstChild("ENDSCREENBLUR") or Instance.new("BlurEffect")
    Blur.Parent = Lighting
    Blur.Name = "ENDSCREENBLUR"

    if State then
        Blur.Size = 0
        ColorCorrection.Brightness = 0
        ColorCorrection.Saturation = 0
        ColorCorrection.Contrast = 0

        EffectUtil:Tween(ColorCorrection, {.35, "Quad"}, {Brightness = -0.225, Contrast = -0.3, Saturation = -1})
        EffectUtil:Tween(Blur, {.45, "Quad"}, {Size = 10})
    else
        EffectUtil:Tween(ColorCorrection, {.35, "Quad"}, {Brightness = 0, Contrast = 0, Saturation = 0})
        EffectUtil:Tween(Blur, {.45, "Quad"}, {Size = 0})
    end
end

local function AnimatePress(Name: string)
    local Button = EndScreen:GetButton(Name)
    Button.UIScale.Scale = 0.75

    local Color = Button.BackgroundColor3
    Button.BackgroundColor3 = Button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.5)
    EffectUtil:Tween(Button, {.6, 'Quad'}, {BackgroundColor3 = Color})
    EffectUtil:Tween(Button.UIScale, {.3, 'Back', 'Out'}, {Scale = 1})

    Disabled[Name] = true
    task.delay(.6, function()
        Disabled[Name] = false
    end)
end

local function RequestLeaveMatch()
    Network:Fire("Match", GameEnum.MatchEvents.RequestMatchLeave)

    AnimatePress("Return")
end

local function RequestAgainMatch()
    Network:Fire("Match", GameEnum.MatchEvents.RequestMatchRepeat)

    AnimatePress("Again")
end


--
function EndScreen:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("EndScreen", true)

    return Main
end

function EndScreen:SetButton(Button: string, State: boolean)
    if UIGroups:GetActiveElementName( "Lobby") ~= nil then
        State = false;
    end

    local ButtonObject = EndScreen:GetButton(Button)
    if ButtonObject then
        ButtonObject.Visible = State
    end
end

function EndScreen:GetButton(Name: string): Frame
    local Frame = self:GetFrame()

    return Frame.Main:FindFirstChild(Name.."Button")
end

function EndScreen:SetHover(Name: string, State: boolean)
    local Button = EndScreen:GetButton(Name)

    if HoverThreads[Name] then
        HoverThreads[Name]:Disconnect()
        Button.Glow.UIGradient.Offset = Vector2.new(-1, 0)
    end

    if Disabled[Name] then return end

    if not State then
        EffectUtil:Tween(Button.UIScale, {.2, 'Quad'}, {Scale = 1})

        return
    end


    EffectUtil:Tween(Button.UIScale, {.2, 'Quad'}, {Scale = 0.95})

    local Alpha = -1
    HoverThreads[Name] = RunService.Heartbeat:Connect(function(delta: number)
        Alpha += delta * 2

        if Alpha >= 1 then
            Alpha = -1
        end

        Button.Glow.UIGradient.Offset = Vector2.new(Alpha, 0)
    end)
end

function EndScreen:Init()
    local Leave = EndScreen:GetButton("Return")

    Leave.Button.MouseButton1Click:Connect(RequestLeaveMatch)
    Leave.Button.MouseEnter:Connect(function()
        EndScreen:SetHover("Return", true)
    end)
    Leave.Button.MouseLeave:Connect(function()
        EndScreen:SetHover("Return", false)
    end)


    --
    local Again = EndScreen:GetButton("Again")
    Again.Button.MouseButton1Click:Connect(RequestAgainMatch)
    Again.Button.MouseEnter:Connect(function()
        EndScreen:SetHover("Again", true)
    end)
    Again.Button.MouseLeave:Connect(function()
        EndScreen:SetHover("Again", false)
    end)
end

function EndScreen:Set(State: boolean)
    local MainFrame = self:GetFrame()

    State = State or not self.__State
    self.__State = State

    MainFrame.Visible = true

    UIGroups.__Groups[self.__Group].Active = State and self.__Name or nil

    LightingEffects(State)

    if State then
        for _, Object in MainFrame.BackgroundEffects:GetChildren() do
            local OriginalTransparency = Object:GetAttribute("OriginalTransparency")
            if not OriginalTransparency then
                OriginalTransparency =  Object.ImageTransparency
                Object:SetAttribute("OriginalTransparency", Object.ImageTransparency)
            end

            Object.ImageTransparency = 1

            if Object.Name == "Shadow" then
                Object.ImageTransparency = 0
                Object.UIScale.Scale = 0
                EffectUtil:Tween(Object.UIScale, {.15, 'Back', 'Out'}, {Scale = 1.33})
            end
            EffectUtil:Tween(Object, {.15}, {ImageTransparency = OriginalTransparency})
        end

        MainFrame.Main.UIScale.Scale = 0
        EffectUtil:Tween(MainFrame.Main.UIScale, {.25, 'Back', "Out"}, {Scale = 1})
    else
        for _, Object in MainFrame.BackgroundEffects:GetChildren() do
            if Object.Name == "Shadow" then
                Object.ImageTransparency = 0
                Object.UIScale.Scale = 1.25
                EffectUtil:Tween(Object.UIScale, {.15, 'Back', 'In'}, {Scale = 0})
            end

            EffectUtil:Tween(Object, {.15}, {ImageTransparency = 1})
        end

        MainFrame.Main.UIScale.Scale = 1
        EffectUtil:Tween(MainFrame.Main.UIScale, {.275, 'Back', "In"}, {Scale = 0})
    end
end

type ServerData = {Status: number, Rank: string}


function EndScreen:ShowData(ServerData: ServerData)
    local Frame = self:GetFrame()
    local Main = Frame.Main

    if ServerData.Status == GameEnum.MatchResults.Victory then
        Main.LossText.Visible = false
        Main.VictoryText.Visible = true
    else
        Main.LossText.Visible = true
        Main.VictoryText.Visible = false
    end

    local RankText = Main.StageInfo.RankText
    RankText.Text = ServerData.Rank

    if ColorInfo[ServerData.Rank] then
        RankText.TextColor3 = ColorInfo[ServerData.Rank][1]
        RankText.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, ColorInfo[ServerData.Rank][2]),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        }
    end
    
end

return EndScreen