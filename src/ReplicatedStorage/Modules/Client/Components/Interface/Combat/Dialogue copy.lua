local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Client = ReplicatedStorage.Modules.Client

local BaseClass = require(Client.Classes.Interface)

local Component = BaseClass.new("Watermark", "Watermark")

function Component:Link(Player: Player)
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Watermark", true)

    return Main
end

function Component:Init()
    if RunService:IsStudio() then
        return;
    end

    local Main = self:GetFrame()
    local BaseText = Main.Used.Base;
    BaseText.Text = `@{Players.LocalPlayer.Name}`

    for i = 1, 7 * 11 do
        local Clone = BaseText:Clone()
        Clone.Visible = true;
        Clone.Parent = Main;
    end
end

return Component
