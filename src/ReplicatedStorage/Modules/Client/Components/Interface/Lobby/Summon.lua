local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local Network = require(Shared.Network)
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local ComponentClass = require(Client.Classes.Interface)
local UIGroups = require(Client.Libraries.UIGroups)

--
local Component = ComponentClass.new(script.Name, 'Lobby', {KeyToBind = Enum.KeyCode.J}) :: Types.UIComponent & Types.UIGetSetButton
local States = {
	MainModel = nil,
	BaseFrame = nil,
}

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
    local Frame = States.BaseFrame

    return Frame:FindFirstChild("Buttons"):FindFirstChild(Name.."Button")
end

function Component:Init()
	local BaseFrame = self:GetFrame().Main.SummonTab
	States.BaseFrame = BaseFrame

	local Summon = Component:GetButton("Summon")
	local SummonTen = Component:GetButton("SummonTen")
	local ReturnBtn = BaseFrame:FindFirstChild("Return")

	Summon.Button.MouseButton1Click:Connect(RequestSummonOne)
	SummonTen.Button.MouseButton1Click:Connect(RequestSummonTen)

	ReturnBtn.Btn.MouseButton1Click:Connect(function()
		self:Set(false)
	end)

	ReturnBtn.MouseEnter:Connect(function()
		Effects:Tween(ReturnBtn.ThinStroke, {0.3, 'Quart'}, {Thickness = 0.04, Color = Color3.fromRGB(245, 47, 47)})
		Effects:Tween(ReturnBtn.UIShadow, {0.5, 'Quart'}, {Transparency = 0.75})
		Effects:Tween(ReturnBtn.UIScale, {0.4, 'Back'}, {Scale = 1.05})
	end)

	ReturnBtn.MouseLeave:Connect(function()
		Effects:Tween(ReturnBtn.ThinStroke, {0.3, 'Quart'}, {Thickness = 0.05, Color = Color3.fromRGB(152, 29, 29)})
		Effects:Tween(ReturnBtn.UIShadow, {0.5, 'Quart'}, {Transparency = 1})
		Effects:Tween(ReturnBtn.UIScale, {0.4, 'Sine'}, {Scale = 1})
	end)

	local CancelThread = nil;
	local Canvas, Main = self:GetFrame().Canvas, self:GetFrame().Main;
	Component:BindToStateChange(function(State: boolean)
		self:GetFrame().Visible = true
		if CancelThread then
			task.cancel(CancelThread)
		end

		if not State then
			BaseFrame.Visible = true
			Canvas.GroupTransparency = 0;
			BaseFrame.Parent = Canvas;
			Effects:Tween(BaseFrame.UIScale, {0.275, 'Quad'}, {Scale = 0.8})
			Effects:Tween(Canvas, {.175}, {GroupTransparency = 1})

			local LobbyMain = UIGroups:GetElementClass("Lobby", "MainMenu")

			LobbyMain:Set(true, true)
		else
			Canvas.GroupTransparency = 1;
			BaseFrame.Parent = Canvas;
			Effects:Tween(BaseFrame.UIScale, {0.3, 'Back'}, {Scale = 1})
			Effects:Tween(Canvas, {.15}, {GroupTransparency = 0})

			CancelThread = task.delay(0.25, function()
				BaseFrame.Parent = Main;
				BaseFrame.Visible = false
			end)
		end
	end)
end

function Component:SetBanner(Data: {Main: string, Sub: {string}})
	local Frame = States.BaseFrame

	for _, Character in Frame.BannerFrame.OtherCharacters.Scroll:GetChildren() do
		if Character:IsA("TextLabel") then
			Character:Destroy()
		end
	end

	local AgentsFolder = Assets.Characters.Agents
	local MainCharFrame = Frame.BannerFrame.MainCharacter
	MainCharFrame.CharName.Text = Data.Main

	local CharacterModel = AgentsFolder:FindFirstChild(Data.Main)
	if CharacterModel then
		if States.MainModel then
			States.MainModel:Destroy()
		end

		local NewCamera = Instance.new("Camera")
		local ClonedCharacter = CharacterModel:Clone()
		ClonedCharacter.Parent = MainCharFrame.Viewport.WorldModel
		ClonedCharacter:PivotTo(CFrame.new())

		NewCamera.FieldOfView = 5
		NewCamera.CFrame = ClonedCharacter:GetPivot() * CFrame.new(0, 0, -85) * CFrame.Angles(0, math.pi, 0)
		MainCharFrame.Viewport.CurrentCamera = NewCamera

		States.MainModel = ClonedCharacter
	end

	--
	for _, Char in Data.Sub do
		local SubChar = Assets.Interface.Lobby.Summon.CharName:Clone()
		SubChar.Text = Char
		SubChar.Parent = Frame.BannerFrame.OtherCharacters.Scroll
	end
end

function Component:SetVisibility(state: boolean)
	local MainFrame = Component:GetFrame()

	MainFrame.Visible = state
end

return Component
