local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Network = require(Shared.Network)
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)

--
local Component = ComponentClass.new(script.Name, 'Lobby', {}) :: Types.UIComponent & Types.UIGetSetButton


--
local function RequestSummonOne()
	Network:Fire("Summon", GameEnum.SummonRequests.SummonOne)
end

local function RequestSummonTen()
	Network:Fire("Summon", GameEnum.SummonRequests.SummonTen)
end

--
function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("Summon", true)

	return Main;
end

function Component:SetButton(Button: string, State: boolean)
    local ButtonObject = Component:GetButton(Button)
    if ButtonObject then
        ButtonObject.Visible = State
    end
end

function Component:GetButton(Name: string): Frame
    local Frame = self:GetFrame()

    return Frame:FindFirstChild(Name.."Button")
end

function Component:Init()
	local Summon = Component:GetButton("Summon")
	local SummonTen = Component:GetButton("SummonTen")

	Summon.Button.MouseButton1Click:Connect(RequestSummonOne)
	SummonTen.Button.MouseButton1Click:Connect(RequestSummonTen)
end

return Component
