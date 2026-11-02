local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets
local Client = ReplicatedStorage.Modules.Client

local Characters = require(Client.Libraries.Characters)

local PULSE_EVERY = 1.5
local PULSE_TIME = 0.3
local FADE_IN = 0.3
local FADE_OUT = 1.5
local EDGE_DEPTH = 10
local MARGIN_MIN = Vector2.new(60, 60)
local MARGIN_MAX = Vector2.new(260, 60)

local Lib = {
    __Part = nil :: BasePart?,
    __Target = nil :: BasePart?,
    __Connection = nil :: RBXScriptConnection?,
    __Bases = {},
    __Alpha = 0,
    __Goal = 0,
    __Clock = 0,
}

local function Apply(Alpha: number)
    for Object, Props in Lib.__Bases do
        for Prop, Base in Props do
            Object[Prop] = 1 - (1 - Base) * Alpha
        end
    end
end

local function GetEdgePoint(Camera: Camera, World: Vector3): Vector3?
    local Size = Camera.ViewportSize
    local Min = MARGIN_MIN
    local Max = Size - MARGIN_MAX
    local Screen = Camera:WorldToViewportPoint(World)
    local Point = Vector2.new(Screen.X, Screen.Y)

    if Screen.Z > 0 and Point.X >= Min.X and Point.X <= Max.X and Point.Y >= Min.Y and Point.Y <= Max.Y then
        return nil
    end

    local Center = (Min + Max) / 2
    local Half = (Max - Min) / 2
    local Direction = Point - Center
    if Screen.Z < 0 then
        Direction = -Direction
    end

    local Scale = math.min(Half.X / math.max(math.abs(Direction.X), 1e-3), Half.Y / math.max(math.abs(Direction.Y), 1e-3))
    local Edge = Center + Direction * Scale
    local Ray = Camera:ViewportPointToRay(Edge.X, Edge.Y)

    return Ray.Origin + Ray.Direction * EDGE_DEPTH
end

local function Step(Delta: number)
    local Agent = Characters:GetCurrent()
    local Part = Lib.__Part
    local Target = Lib.__Target
    if not Agent or not Part or not Target or not Target.Parent then
        return
    end

    local Gui = Part.WhereToGoIndicator
    local Position = Agent:GetPivot().Position
    local World = Vector3.new(Target.Position.X, Position.Y, Target.Position.Z)
    local Distance = (World - Position).Magnitude

    if Distance <= math.min(Target.Size.X, Target.Size.Z) / 2 then
        Lib.__Goal = 0
    end

    local Rate = Delta / (Lib.__Goal > Lib.__Alpha and FADE_IN or FADE_OUT)
    Lib.__Alpha = math.clamp(Lib.__Alpha + math.sign(Lib.__Goal - Lib.__Alpha) * Rate, 0, 1)

    if Lib.__Goal == 0 and Lib.__Alpha == 0 then
        Lib:Clear()

        return
    end

    Part.Position = GetEdgePoint(workspace.CurrentCamera, World) or World
    Gui.TextLabel.Text = math.floor(Distance)..'m'
    Apply(Lib.__Alpha)

    Lib.__Clock += Delta
    local Phase = Lib.__Clock % PULSE_EVERY
    local Effect = Gui.EffectCircle

    if Phase < PULSE_TIME then
        local Progress = Phase / PULSE_TIME

        Effect.UIScale.Scale = 0.15 + 0.3 * Progress
        Effect.BackgroundTransparency = 1 - 0.6 * (1 - Progress) * Lib.__Alpha
    else
        Effect.BackgroundTransparency = 1
    end
end

function Lib:Show(Target: BasePart)
    Lib:Clear()

    local Part = Assets.Interface.WhereToIndicator:Clone()
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false

    local Gui = Part.WhereToGoIndicator
    Gui.SizeOffset = Vector2.new(0.25, 0)

    for _, Object in Gui:GetDescendants() do
        if Object == Gui.EffectCircle then
            continue
        elseif Object:IsA("TextLabel") then
            Lib.__Bases[Object] = {BackgroundTransparency = Object.BackgroundTransparency, TextTransparency = Object.TextTransparency}
        elseif Object:IsA("GuiObject") then
            Lib.__Bases[Object] = {BackgroundTransparency = Object.BackgroundTransparency}
        elseif Object:IsA("UIStroke") then
            Lib.__Bases[Object] = {Transparency = Object.Transparency}
        end
    end

    Lib.__Part = Part
    Lib.__Target = Target
    Lib.__Alpha = 0
    Lib.__Goal = 1
    Lib.__Clock = 0

    Apply(0)
    Gui.EffectCircle.BackgroundTransparency = 1
    Part.Parent = workspace

    Lib.__Connection = RunService.RenderStepped:Connect(Step)
end

function Lib:Hide()
    Lib.__Goal = 0
end

function Lib:Clear()
    if Lib.__Connection then
        Lib.__Connection:Disconnect()
    end

    if Lib.__Part then
        Lib.__Part:Destroy()
    end

    Lib.__Connection = nil
    Lib.__Part = nil
    Lib.__Target = nil
    Lib.__Bases = {}
end

return Lib
