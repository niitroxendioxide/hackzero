local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets
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

    return Frame:FindFirstChild("Buttons"):FindFirstChild(Name.."Button")
end

function Component:Init()
	local Summon = Component:GetButton("Summon")
	local SummonTen = Component:GetButton("SummonTen")

	Summon.Button.MouseButton1Click:Connect(RequestSummonOne)
	SummonTen.Button.MouseButton1Click:Connect(RequestSummonTen)
end

function Component:SetBanner(Data: {Main: string, Sub: {string}})
	local Frame = Component:GetFrame()

	for _, Character in Frame.BannerFrame.OtherCharacters.Scroll:GetChildren() do
		if Character:IsA("TextLabel") then
			Character:Destroy()
		end
	end

	Frame.BannerFrame.MainCharacter.CharName.Text = Data.Main

	for _, Char in Data.Sub do
		local SubChar = Assets.Interface.Lobby.Summon.CharName:Clone()
		SubChar.Text = Char
		SubChar.Parent = Frame.BannerFrame.OtherCharacters.Scroll
	end
end

return Component
