const ServerStorage = game:GetService("ServerStorage")
const TweenService = game:GetService("TweenService")

const Services = ServerStorage.Modules.Services
const Libraries = ServerStorage.Modules.Libraries

const PlayersLibrary = require(Libraries.Players)
const AgentService = require(Services.Combat.AgentService)
const MatchInteractionService = require(Services.Match.MatchInteractionService)

const DEFAULT_COLOR = Color3.fromRGB(255, 170, 40)
const TICK = 0.1

type CleanserData = {
    Radius: number?,
    Expanded: number?,
    Duration: number?,
    Core: string?,
    Color: Color3?,
    Pickup: boolean?,
    SetValues: {[string]: any}?,
}

type Zone = {
    Id: string,
    Data: CleanserData,
    Marker: BasePart,
    Radius: number,
    Completed: boolean,
    Part: BasePart?,
    Core: BasePart?,
    InteractionId: number?,
    Event: any?,
}

const Service = {
    __Mission = nil :: any,
    __Data = {} :: {[string]: CleanserData},
    __Zones = {} :: {[string]: Zone},
    __Prompts = {} :: {[number]: Zone},
}

const function GetMarker(Id: string): BasePart?
    const Map = workspace.World:FindFirstChild("Map")
    const Markers = Map and Map:FindFirstChild("Markers")

    return Markers and Markers:FindFirstChild(Id) :: BasePart?
end

const function GetEffectsFolder(): Instance
    return workspace.World:FindFirstChild("Effects") or workspace
end

const function Flat(Position: Vector3): Vector3
    return Vector3.new(Position.X, 0, Position.Z)
end

const function AnyAgentInside(Zone: Zone): boolean
    const Center = Flat(Zone.Marker.Position)

    for _, StagePlayer in PlayersLibrary:GetAll() do
        const Agent = AgentService:GetCurrentCharacter(StagePlayer:GetBase())
        if Agent and Agent:IsAlive() and (Flat(Agent:GetPivot().Position) - Center).Magnitude <= Zone.Radius then
            return true
        end
    end

    return false
end

const function CreateZonePart(Zone: Zone, Color: Color3): BasePart
    const Part = Instance.new("Part")
    Part.Name = Zone.Id .. "_Zone"
    Part.Shape = Enum.PartType.Cylinder
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.CastShadow = false
    Part.Material = Enum.Material.Neon
    Part.Transparency = 0.75
    Part.Color = Color
    Part.Size = Vector3.new(0.4, Zone.Radius * 2, Zone.Radius * 2)
    Part.CFrame = CFrame.new(Zone.Marker.Position) * CFrame.Angles(0, 0, math.rad(90))
    Part.Parent = GetEffectsFolder()

    return Part
end

const function RevealCore(Zone: Zone, Color: Color3)
    const Core = Instance.new("Part")
    Core.Name = Zone.Data.Core or "Core"
    Core.Shape = Enum.PartType.Ball
    Core.Anchored = true
    Core.CanCollide = false
    Core.CanQuery = false
    Core.CanTouch = false
    Core.Material = Enum.Material.Neon
    Core.Color = Color
    Core.Size = Vector3.new(2.5, 2.5, 2.5)
    Core.CFrame = CFrame.new(Zone.Marker.Position + Vector3.new(0, 3, 0))

    const Light = Instance.new("PointLight")
    Light.Color = Color
    Light.Brightness = 3
    Light.Range = 18
    Light.Parent = Core

    const Sparkles = Instance.new("ParticleEmitter")
    Sparkles.Color = ColorSequence.new(Color)
    Sparkles.LightEmission = 1
    Sparkles.Rate = 12
    Sparkles.Lifetime = NumberRange.new(0.8, 1.4)
    Sparkles.Speed = NumberRange.new(1, 3)
    Sparkles.SpreadAngle = Vector2.new(180, 180)
    Sparkles.Size = NumberSequence.new(0.3, 0)
    Sparkles.Parent = Core

    Core.Parent = GetEffectsFolder()
    Zone.Core = Core

    if Zone.Data.Pickup then
        const Object = MatchInteractionService:AddInteraction({
            Type = 'ItemPickup',
            Collider = Core,
            Tag = Zone.Data.Core,
            CleanserId = Zone.Id,
            Drops = {
                {Type = '_mission_object', Extra = {Name = Zone.Data.Core}, Amount = 1},
            },
            SetValues = {
                ['Recovered_' .. Zone.Id] = true,
            },
        })

        if Object then
            Zone.InteractionId = Object.Id
            Service.__Prompts[Object.Id] = Zone
        end
    end
end

const function Complete(Zone: Zone)
    Zone.Completed = true

    const Data = Zone.Data
    const Color = Data.Color or DEFAULT_COLOR
    const Expanded = Data.Expanded or Zone.Radius * 2.5

    Zone.Radius = Expanded

    if Zone.Part then
        TweenService:Create(Zone.Part, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {
            Size = Vector3.new(0.4, Expanded * 2, Expanded * 2),
            Transparency = 0.85,
        }):Play()
    end

    RevealCore(Zone, Color)

    if Service.__Mission then
        const Values = table.clone(Data.SetValues or {})
        Values['Cleansed_' .. Zone.Id] = true

        Service.__Mission:ApplySetValues(Values)
    end
end

const function Activate(Zone: Zone, EventObject: any)
    const Data = Zone.Data
    Zone.Part = CreateZonePart(Zone, Data.Color or DEFAULT_COLOR)

    const StepTime = (Data.Duration or 30) / 100
    local Held = 0
    local Progress = 0

    while Progress < 100 do
        if EventObject:IsFinished() or Service.__Mission == nil or Service.__Mission:IsFinished() then
            return
        end

        if AnyAgentInside(Zone) then
            Held += TICK

            while Held >= StepTime and Progress < 100 do
                Held -= StepTime
                Progress += 1
                EventObject:UpdateProgress('Cleanse', 1)
            end
        end

        task.wait(TICK)
    end

    Complete(Zone)
end

const function Arm(Id: string, EventObject: any)
    const Data = Service.__Data[Id]
    const Marker = GetMarker(Id)
    if not Data or not Marker then
        warn("[CleanserService] Missing data or marker for", Id)

        return
    end

    const Zone: Zone = {
        Id = Id,
        Data = Data,
        Marker = Marker,
        Radius = Data.Radius or 14,
        Completed = false,
        Event = EventObject,
    }

    Service.__Zones[Id] = Zone

    const Object = MatchInteractionService:AddInteraction({
        Type = 'AnimaCleanser',
        Collider = Marker,
        CleanserId = Id,
    })

    if not Object then
        return
    end

    Zone.InteractionId = Object.Id
    Service.__Prompts[Object.Id] = Zone
end

function Service:Init()
    MatchInteractionService.triggered:Connect(function(Id: number, Core: {[string]: any})
        const Zone = Service.__Prompts[Id]
        if not Zone then
            return
        end

        Service.__Prompts[Id] = nil
        MatchInteractionService:RemoveInteraction(Id)

        if Core.Type == 'AnimaCleanser' then
            task.spawn(Activate, Zone, Zone.Event)
        elseif Core.Type == 'ItemPickup' and Zone.Core then
            Zone.Core:Destroy()
            Zone.Core = nil
        end
    end)
end

function Service:Bind(Mission: any, Cleansers: {[string]: CleanserData}?)
    Service.__Mission = Mission
    Service.__Data = Cleansers or {}

    Mission.EventStarted:Connect(function(_Name: string, EventObject: any, EventData: {[string]: any})
        if typeof(EventData.Cleanser) == 'string' then
            Arm(EventData.Cleanser, EventObject)
        end
    end)
end

function Service:IsProtected(Position: Vector3): (boolean, boolean)
    const At = Flat(Position)
    local Protected = false

    for _, Zone in Service.__Zones do
        if not Zone.Part then
            continue
        end

        if (At - Flat(Zone.Marker.Position)).Magnitude <= Zone.Radius then
            if Zone.Completed then
                return true, true
            end

            Protected = true
        end
    end

    return Protected, false
end

function Service:GetZone(Id: string)
    return Service.__Zones[Id]
end

return Service
