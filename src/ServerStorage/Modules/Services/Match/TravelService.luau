const ServerStorage = game:GetService("ServerStorage")

const Services = ServerStorage.Modules.Services
const Libraries = ServerStorage.Modules.Libraries

const PlayersLibrary = require(Libraries.Players)
const AgentService = require(Services.Combat.AgentService)
const MatchInteractionService = require(Services.Match.MatchInteractionService)

const SPREAD = 6

type ShipData = {
    From: string,
    To: string,
}

type Pending = {
    Ship: ShipData,
    Event: any,
}

const Service = {
    __Mission = nil :: any,
    __Prompts = {} :: {[number]: Pending},
}

const function GetMarker(Id: string): BasePart?
    const Map = workspace.World:FindFirstChild("Map")
    const Markers = Map and Map:FindFirstChild("Markers")

    return Markers and Markers:FindFirstChild(Id) :: BasePart?
end

function Service:Travel(To: string): boolean
    const Landing = GetMarker(To)
    if not Landing then
        warn("[TravelService] No landing marker:", To)

        return false
    end

    for Index, StagePlayer in PlayersLibrary:GetAll() do
        const Angle = (Index - 1) * (math.pi * 2 / 4)
        const Offset = Vector3.new(math.cos(Angle), 0, math.sin(Angle)) * (Index > 1 and SPREAD or 0)

        AgentService:SnapTo(StagePlayer:GetBase(), CFrame.new(Landing.Position + Offset))
    end

    return true
end

function Service:Init()
    MatchInteractionService.triggered:Connect(function(Id: number, _Core)
        const Entry = Service.__Prompts[Id]
        if not Entry then
            return
        end

        Service.__Prompts[Id] = nil
        MatchInteractionService:RemoveInteraction(Id)

        if Entry.Event:IsFinished() then
            return
        end

        if Service:Travel(Entry.Ship.To) then
            Entry.Event:UpdateProgress('Travel', true)
        end
    end)
end

function Service:Bind(Mission: any)
    Service.__Mission = Mission

    Mission.EventStarted:Connect(function(_Name: string, EventObject: any, EventData: {[string]: any})
        const Ship = EventData.Ship
        if typeof(Ship) ~= 'table' then
            return
        end

        const Door = GetMarker(Ship.From)
        if not Door then
            warn("[TravelService] No ship marker:", Ship.From)

            return
        end

        const Object = MatchInteractionService:AddInteraction({
            Type = 'Ship',
            Collider = Door,
        })

        if Object then
            Service.__Prompts[Object.Id] = {Ship = Ship, Event = EventObject}
        end
    end)
end

return Service
