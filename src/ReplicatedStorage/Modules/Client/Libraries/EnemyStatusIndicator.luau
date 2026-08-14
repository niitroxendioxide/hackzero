----
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local _Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

---
local Effects = require(Shared.Utility.Effects)
local Types = require(Shared.Types.Abilities)
local IconDatabase = require(Shared.Database.Icons)

---
local Lib = {
    __Cache = {}
}

function Lib:AddIndicator(Id: number, Enemy: Types.ClientEnemy)
    if Lib.__Cache[Id] then
        return    
    end

    local Indicator = Effects:Create(Assets.Interface.Combat.BillboardFight, 10)
	local Billboard = Indicator.Billboard
	local Gui = Billboard.BillboardGui

	Billboard.Parent = Enemy:GetModel().Head
	Billboard.Position = Vector3.yAxis * 2.5

    Gui.Meters.StunPercent.Text = '0'
	Gui.Meters.Health.Main.UIGradient.Offset = Vector2.new(.2, 0)

    Lib.__Cache[Id] = {Gui, Enemy}
end

function Lib:UpdateHealth(Id: number, Current: number)
    local Cache = Lib.__Cache[Id];
    if not Cache then
        return
    end

    local Gui = Cache[1];
    local Maximum = Cache[2]:GetStat('Max_Health')
    local HealthValue = math.clamp(Current / Maximum, 0, 1)

    Gui.Meters.Health.Main.UIGradient.Offset = Vector2.new(-0.81 + HealthValue, 0)
end

function Lib:UpdateDaze(Id: number, TotalDaze: number)
    local Cache = Lib.__Cache[Id];
    if not Cache then
        return
    end

    local Gui = Cache[1];
    local Enemy = Cache[2];

    local MaxDaze = Enemy:GetStat("Max_Daze")
    local DazeValue = math.clamp(TotalDaze / MaxDaze, 0, 1)
    Effects:Tween(Gui.Meters.Stun.Main.UIGradient, {.3, 'Quad'}, {Offset = Vector2.new(-0.81 + DazeValue, 0)})

    local IsDazed = Enemy:IsKnocked()
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
end

function Lib:UpdateAffliction(Id: number, Percent: number, NewElement: string?)
    local Cache = Lib.__Cache[Id];
    if not Cache then
        return
    end

    local Gui = Cache[1];

    if NewElement and NewElement ~= 'None' then
        local ElementColors = IconDatabase.Elements.Colors[NewElement]
        local ElementIcon = IconDatabase.Elements[NewElement]

        for _, Item in Gui.Effect.Bar:GetChildren() do
            Item.ImageLabel.ImageColor3 = ElementColors.Meter
        end

        Gui.Effect.Icon.Image = ElementIcon
        Gui.Effect.Icon.ImageColor3 = ElementColors.Main
        Gui.Effect.Icon.UIGradient.Color = ElementColors.Gradient

        Effects:Tween(Gui.Effect.UIScale, {.45, 'Back', 'Out'}, {Scale = 1})
    end

    local LowPart = math.clamp(Percent / 50, 0, 1)
    local TopPart = math.clamp((Percent - 50) / 50, 0, 1)

    Gui.Effect.Bar['1'].ImageLabel.UIGradient.Rotation = 180 - 181 * TopPart
    Gui.Effect.Bar['2'].ImageLabel.UIGradient.Rotation = 360 - 181 * LowPart
    Gui.Effect.Visible = true
end

function Lib:RemoveIndicator(Id: number)
    local Cache = Lib.__Cache[Id];
    if not Cache then
        return
    end

    if typeof(Cache[1]) == 'Instance' and Cache[1]:IsDescendantOf(workspace) then
        Cache[1]:Destroy()
    end

    Lib.__Cache[Id] = nil
end

return Lib