local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client

local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local ComponentClass = require(Client.Classes.Interface)

local ATTRIBUTE = 'Corruption'
local COLORS = {
	Low = Color3.fromRGB(165, 90, 255),
	Half = Color3.fromRGB(215, 60, 210),
	Max = Color3.fromRGB(255, 40, 110),
}

local Component = ComponentClass.new(script.Name, 'HUD', {})

local function Build(Parent: Instance): Frame
	local Frame = Instance.new("Frame")
	Frame.Name = "Corruption"
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Position = UDim2.fromScale(0.5, 0.86)
	Frame.Size = UDim2.new(0.22, 0, 0, 12)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	Frame.BackgroundTransparency = 0.3
	Frame.BorderSizePixel = 0
	Frame.Visible = false

	local Fill = Instance.new("Frame")
	Fill.Name = "Fill"
	Fill.Size = UDim2.fromScale(0, 1)
	Fill.BackgroundColor3 = COLORS.Low
	Fill.BorderSizePixel = 0
	Fill.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.AnchorPoint = Vector2.new(0.5, 1)
	Label.Position = UDim2.new(0.5, 0, 0, -2)
	Label.Size = UDim2.new(1, 0, 0, 14)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.GothamBold
	Label.TextScaled = true
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.Text = "CORRUPTION 0%"
	Label.Parent = Frame

	Frame.Parent = Parent

	return Frame
end

function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
	if not HUD then return end

	return HUD:FindFirstChild("Corruption", true) or Build(HUD)
end

function Component:Init()
	local Frame = Component:GetFrame()

	local function Update()
		local Value = Player:GetAttribute(ATTRIBUTE)
		if Value == nil then
			Frame.Visible = false

			return
		end

		Frame.Visible = true

		local Color = if Value >= 100 then COLORS.Max elseif Value >= 50 then COLORS.Half else COLORS.Low
		local Fill = Frame:FindFirstChild("Fill")
		if Fill then
			Effects:Tween(Fill, {0.25, 'Sine'}, {Size = UDim2.fromScale(Value / 100, 1), BackgroundColor3 = Color})
		end

		local Label = Frame:FindFirstChild("Label")
		if Label then
			Label.Text = `CORRUPTION {Value}%`
		end
	end

	Player:GetAttributeChangedSignal(ATTRIBUTE):Connect(Update)
	Update()
end

return Component
