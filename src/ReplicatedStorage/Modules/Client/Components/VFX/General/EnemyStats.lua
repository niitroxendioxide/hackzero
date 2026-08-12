---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')


local Assets = ReplicatedStorage.Assets
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)
local Fusion = require(Client.Libraries.Fusion)
local IconDatabase = require(Shared.Database.Icons)

local Scope = Fusion.scoped(Fusion)
local peek = Fusion.peek

---
return function(Enemy: Types.EnemyClass)
	if typeof(Enemy) == 'nil' then return end

	local Indicator = Effects:Create(Assets.Interface.Combat.BillboardFight, 10)
	local Billboard = Indicator.Billboard
	local Gui = Billboard.BillboardGui

	Billboard.Parent = Enemy:GetModel().Head
	Billboard.Position = Vector3.yAxis * 2.5

	--
	local Affliction_Spring = Scope:Spring(Enemy.__Affliction, 25, 0.65)
	local Health_Spring = Scope:Spring(Enemy.__Health, 20, 0.8)

	Gui.Meters.Health.Main.UIGradient.Offset = Vector2.new(.2, 0)

	Scope:Observer(Enemy.__Affliction_Type):onChange(function()
		local Element = peek(Enemy.__Affliction_Type)

		for _, Item in Gui.Effect.Bar:GetChildren() do
			Item.ImageLabel.ImageColor3 = IconDatabase.Elements.Colors[Element].Meter
		end

		Gui.Effect.Icon.Image = IconDatabase.Elements[Element]
		Gui.Effect.Icon.ImageColor3 = IconDatabase.Elements.Colors[Element].Main
		Gui.Effect.Icon.UIGradient.Color = IconDatabase.Elements.Colors[Element].Gradient

		Effects:Tween(Gui.Effect.UIScale, {.45, 'Back', 'Out'}, {Scale = 1})
	end)

	local Connection; Connection = RunService.Heartbeat:Connect(function(_)
		if not Billboard:IsDescendantOf(workspace) then
			Connection:Disconnect()
			return
		end

		if not Enemy:IsVisible() then
			Gui.Enabled = false
			return
		end

		Gui.Enabled = true

		local SpringVal = peek(Health_Spring)
		local MaxVal = Enemy:GetStat('Max_Health')
		local TotalDaze = peek(Enemy.__Daze)
		local HealthValue = math.clamp(SpringVal / MaxVal, 0, 1)
		local DazeValue = math.clamp(TotalDaze / Enemy:GetStat("Max_Daze"), 0, 1)

		local IsDazed = Enemy.__Status:IsKnocked()

		--Billboard.Position = Vector3.xAxis * 0 --(5 + Height)
		Gui.Meters.Health.Main.UIGradient.Offset = Vector2.new(-0.81 + HealthValue, 0)
		Effects:Tween(Gui.Meters.Stun.Main.UIGradient, {.3, 'Quad'}, {Offset = Vector2.new(-0.81 + DazeValue, 0)})

		--print(DazeValue)
		Gui.Meters.StunPercent.Text = math.floor(DazeValue * 100)
		Gui.Meters.StunPercentBG.Text = Gui.Meters.StunPercent.Text

		Gui.Meters.StunDamageBonus.Visible = IsDazed

		local Mult = math.clamp((TotalDaze / Enemy:GetStat("Max_Daze")) / 0.25, 0, 1)
		if IsDazed then
			Gui.Meters.Stun.Main.ImageColor3 = Color3.fromRGB(40, 33, 255)
			Gui.Meters.Stun.Effect.ImageColor3 = Color3.fromRGB(238, 171, 255)
			Gui.Meters.Stun.Effect.Transparency = 1 - (0.35) * Mult
			Gui.Meters.StunDamageBonus.Text = 'Damage '..math.floor(Enemy.__Status:GetDazeMultiplier() * 100)..'%'
		else
			Gui.Meters.Stun.Effect.Transparency = 1 - (0.45) * Mult
			Gui.Meters.Stun.Effect.ImageColor3 = Color3.new(1)
			Gui.Meters.Stun.Main.ImageColor3 = Color3.fromRGB(255, 131, 43)
		end

		-- >>
		local AfflictionSpringVal = peek(Affliction_Spring)

		local LowPart = math.clamp(AfflictionSpringVal / 50, 0, 1)
		local TopPart = math.clamp((AfflictionSpringVal - 50) / 50, 0, 1)

		Gui.Effect.Bar['1'].ImageLabel.UIGradient.Rotation = 180 - 181 * TopPart
		Gui.Effect.Bar['2'].ImageLabel.UIGradient.Rotation = 360 - 181 * LowPart
		Gui.Effect.Visible = true
	end)
end
