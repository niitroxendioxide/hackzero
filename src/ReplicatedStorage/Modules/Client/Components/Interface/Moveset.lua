--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Types = require(Shared.Types)
local EffectUtil = require(Shared.Utility.Effects)
local IconDatabase = require(Database.Icons)
local ComponentClass = require(Client.Classes.Interface)

--
local Component = ComponentClass.new("AFK", "AFK")

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("Moveset", true)

    return Main
end

function Component:Init()
    --
    --local MainFrame = Component:GetFrame()

end

function Component:PlayCooldown(Skill: string, Time: number)
    local MainFrame = Component:GetFrame()
    local Buttons = MainFrame:FindFirstChild("Buttons")
    local SkillFrame = Buttons:FindFirstChild(Skill) :: {Cooldown: CanvasGroup & {Fill: Frame}}

    if not SkillFrame then
        return
    end

    local FillCooldownObj = SkillFrame.Cooldown.Fill

    FillCooldownObj.Size = UDim2.fromScale(1, 1)
    EffectUtil:Tween(FillCooldownObj, {Time, 'Quad'}, {Size = UDim2.fromScale(1, 0)})
end

return Component :: Types.UIComponent