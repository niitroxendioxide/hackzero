local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local Assets = ReplicatedStorage.Assets
local World = workspace:FindFirstChild("World")

local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local EffectUtil = require(Shared.Utility.Effects)
local IconDatabase = require(Database.Icons)
local ComponentClass = require(Client.Classes.Interface)

--
local function ToHMS(Seconds: number)
	return string.format("%02i:%02i:%02i", Seconds/60^2, Seconds/60%60, Seconds%60)
end


--
local Component = ComponentClass.new("AFK", "AFK")

function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("AFKHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("AFK", true)

    return Main
end

function Component:Init()
    --
    local MainFrame = Component:GetFrame()
    local Scope = Component:GetScope()
    local SecondsCounted = 0;

    table.insert(Scope, RunService.Heartbeat:Connect(function(Delta: number)
        SecondsCounted += Delta

        MainFrame.Data.TimeCounter.Text = `Time Active: {ToHMS(SecondsCounted)}`
    end))
end

function Component:ShowCurrency(Type: string, Value: number)
    local MainFrame = Component:GetFrame()
    local DataFrame = MainFrame.Data
    local CurrencyList = DataFrame.Currencies

    local ItemObj = CurrencyList:FindFirstChild(Type)
    if ItemObj  then
        ItemObj.Design.CurrencyVal.Text = tostring(Value)
        return
    end

    --
    ItemObj = Assets.Interface.AFK.Currency:Clone()
    ItemObj.Design.Icon.Image = 'rbxassetid://' .. (IconDatabase.Currency[Type] or 0)
    ItemObj.Name = Type
    ItemObj.Parent = CurrencyList
end

return Component :: Types.UIComponent