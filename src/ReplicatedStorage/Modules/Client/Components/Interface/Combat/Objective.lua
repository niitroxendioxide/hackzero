local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Types = require(Shared.Types)
local Stages = require(Shared.Database.Stages)
local EventStates = require(Client.States.Events)
local ComponentClass = require(Client.Classes.Interface)

--
local State = {
    Observers = {},

    Stage = "",
    Act = "",
    Mode = 'Mission',
    ClockBeginTime = os.clock(),
    ClockMaxTime = 9999,
}
local Component = ComponentClass.new(script.Name, 'HUD', {})

function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("Objective", true)

	return Main;
end

function Component:Init()
    --
    local ObjectiveFrame = Component:GetFrame()

    task.spawn(function()

        while task.wait() do
            if State.Mode == 'Mission' then
                continue
            end

            local TimeSince = math.floor(os.clock() - State.ClockBeginTime)
            local CountDownTime = State.ClockMaxTime - TimeSince;
            local Minutes = math.floor(CountDownTime / 60)
            local Seconds = CountDownTime % 60

            ObjectiveFrame.Waves.Time.Text = string.format("%02d:%02d", Minutes, Seconds)
        end

    end)
end

function Component:CreateEvent(Event: string)
    if State.Stage == "" or State.Act == "" then
        return
    end

    if State.Mode ~= 'Mission' then
        return;
    end

    local EventData = Stages:GetEvent(State.Stage, State.Act, Event)

    if not EventData then
        return
    end

    if State.Observers[Event] then
        for _, Disconnector in State.Observers[Event] do
            Disconnector()
        end
    end

    --
    local Scope = self:GetScope()
    State.Observers[Event] = {}

    local Frame = self:GetFrame()
    Frame.Mission.Visible = true
    Frame.Waves.Visible = false

    local Values = EventStates:New(Event, EventData.Goal)
    local Object = Assets.Combat.Objective.GoalObject:Clone()
    Object.Label.Text = EventData.Objective
    Object.Parent = Frame.Mission.Goals

    Object:SetAttribute("Event", Event)

    local function updateText()
        local result = string.gsub(EventData.Objective, "{objective%[(%w+)%]}", function(key)
            local Value = EventStates:Get(Event, key, false)

            return `{Value}/{EventData.Goal[key]}` or "["..key.." not found]"
        end)

        if not Object:FindFirstChild('Label') then return end
        Object.Label.Text = result

        local ExtraChars = math.clamp(#result - 20, 0, 17)
        Object.Background.Size = UDim2.fromScale(0.634 + (ExtraChars) * 0.02, 0.995)
    end

    updateText()

    for Name, Value in Values do
        local Observer = Scope:Observer(Value)
        local disconnect = Observer:onChange(updateText)

        table.insert(State.Observers[Event], disconnect)
    end
end

function Component:DeleteEvent(Event: string)
    local Frame = self:GetFrame()

    for _, Objectives in Frame.Mission.Goals:GetChildren() do
        if Objectives:GetAttribute("Event") == Event then
            Objectives:Destroy()
        end
    end
end

function Component:SetStage(StageName: string, ActName: string)
    State.Stage = StageName
    State.Act = ActName
end

function Component:SetWave(WaveId: number, Total: number)
    if State.Mode == 'Mission' then
        return;
    end

    local Frame = Component:GetFrame()
    Frame.Mission.Visible = false
    Frame.Waves.Visible = true

    local Waves = Frame.Waves;
    Waves.Counter.Text = `Current Wave: {WaveId} / {Total}`
end

function Component:SetMode(ModeName: string, Data: {}?)
    State.Mode = ModeName

    Data = Data or {}

    if ModeName == 'Waves' then
        State.ClockBeginTime = os.clock()
        State.ClockMaxTime = Data.Time or 6_000 --seconds
    end
end

return Component :: Types.UIComponent
