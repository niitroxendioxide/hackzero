local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets

local Types = require(Shared.Types)
local LocalData = require(Client.Libraries.LocalData)
local ComponentClass = require(Client.Classes.Interface)

local Component = ComponentClass.new("Feeding", "Feeding")
local Menus = {"Agent"}
local States = {
    AgentModel = nil,
}

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Feeding", true)

    return Main
end

function Component:Init()
    local MainFrame = Component:GetFrame()

    Component:Set(true)

    MainFrame.Agent.Close.Button.MouseButton1Click:Connect(function()
        Component:SetMenu("Agent", false)
    end)
end

function Component:SetMenu(MenuName: string, State: boolean)
    local MainFrame = Component:GetFrame()
    local MenuFrame = MainFrame:FindFirstChild(MenuName)
    if not MenuFrame then
        return
    end

    if State then
        for _, OtherMenuName in Menus do
            if OtherMenuName ~= MenuName then
                Component:Set(OtherMenuName, false)
            end
        end
    end

    MenuFrame.Visible = State

    return MenuFrame
end

function Component:IsActive(MenuName: string)
    local MainFrame = Component:GetFrame()
    local MenuFrame = MainFrame:FindFirstChild(MenuName)

    if not MenuFrame then
        return false
    end

    return MenuFrame.Visible == true
end

function Component:ShowAgentFeeding(AgentName: string)
    local AgentMenu = Component:SetMenu("Agent", true)
    if not AgentMenu then
        return
    end

    local Info = LocalData:GetAgent(AgentName)
    local DataFrame = AgentMenu.Data

    DataFrame.AgentName.Text = AgentName
    DataFrame.LvlBar.Lvl.Text = `Level: {Info.Level} / 60`

    --
    local Model = Assets.Characters.Agents:FindFirstChild(AgentName)
    if Model then
        if States.AgentModel then
            States.AgentModel:Destroy()
        end

        local NewCamera = Instance.new('Camera')
        local Cloned = Model:Clone()
        Cloned.Parent = DataFrame.Viewport.WorldModel
        Cloned:PivotTo(CFrame.new())

        NewCamera.FieldOfView = 1
        NewCamera.CFrame = Cloned:GetPivot() * CFrame.new(0, 1.75, -220) * CFrame.Angles(0, math.pi, 0)
        DataFrame.Viewport.CurrentCamera = NewCamera

        States.AgentModel = Cloned
    end
end

return Component :: Types.UIComponent

