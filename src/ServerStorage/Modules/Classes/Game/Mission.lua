--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Services = Modules.Services

local Types = require(Shared.Types)
local Stages = require(Database.Stages)
local Signal = require(Shared.Utility.Signal)
local Hitbox = require(Modules.Libraries.Hitbox)
local EventClass = require(script.Parent.Event)
local PlayersLibrary = require(Modules.Libraries.Players)
local AgentService = require(Services.Combat.AgentService)

--
local function GetTrigger(Name: string?): BasePart?
    if Name == nil then return end

    local World = workspace:FindFirstChild("World") :: Folder
    local Map = World:FindFirstChild("Map")

    if Map:FindFirstChild("Triggers") then
        return Map.Triggers:FindFirstChild(Name)
    end

    return nil
end


--
local MissionClass = {}
MissionClass.__index = MissionClass

function MissionClass.new(Stage: string, Act: string): Types.MissionClass
    local self = setmetatable({}, MissionClass)
    self.Finished = Signal.new()

    self.__Active = false
    self.__Act = Act;
    self.__Stage = Stage;
    self.__Current_Events = {};
    self.__Current_Active_Triggers = {};

    return self
end

--
function MissionClass.Begin(self: Types.MissionClass)
    if self.__Active then
        return
    end

    self.__Active = true

    self:DetectAreaTriggers()
    self:BeginEvent("Begin", PlayersLibrary:GetAll())
end

function MissionClass.BeginEvent(self: Types.MissionClass, Event: string, Players: {Types.StagePlayer})
    local EventData = Stages:GetEvent(self.__Stage, self.__Act, Event :: string)
    if EventData == nil then
        return
    end

    print(self.__Current_Events)
    if self.__Current_Events[Event] ~= nil then
        if not self.__Current_Events[Event]:IsFinished() then
            for _, Player in Players do
                self.__Current_Events[Event]:AddPlayer(Player)
            end
        end

        return
    end

    -- Start event
    local EventObject = EventClass.new(self.__Stage, self.__Act, Event :: string)

    if EventData.Global then
        local Rng = Random.new()
        local Area = GetTrigger(EventData.EventPlace);

        for _, Player in PlayersLibrary:GetAll() do
            if Area then
                local Size = Area.Size
                local Spot = Area:GetPivot()
                local Offset = CFrame.new(Rng:NextInteger(-Size.X/2, Size.X/2), 0, Rng:NextInteger(-Size.Z/2, Size.Z/2))

                AgentService:SnapTo(Player:GetBase(), Spot * Offset)
            end

            EventObject:AddPlayer(Player)
        end
    else
        for _, Player in Players do
            EventObject:AddPlayer(Player)
        end
    end

    EventObject.Finished:Once(function(Next_Stage: string)
        if Next_Stage == "End" then
            self.Finished:Fire()

            return
        elseif Next_Stage == "None" then
            return
        end

        self:BeginEvent(Next_Stage, Players)
    end)

    EventObject:Start()

    self.__Current_Events[Event] = EventObject
end

function MissionClass.DetectAreaTriggers(self: Types.MissionClass)
    local World = workspace:FindFirstChild("World") :: Folder
    local Map = World:FindFirstChild("Map")

    if Map:FindFirstChild("Triggers") then
        for _, Area in Map.Triggers:GetChildren() do
            local Connection; Connection = RunService.Heartbeat:Connect(function()
                Hitbox:ForAgentsInZone(Area.Size, Area.CFrame, function(Agent)
                    local ReachPlace = false;

                    for EventName, Event: Types.EventClass in self.__Current_Events do
                        if Event:HasGoal("ReachPlace") then
                            Event:UpdateProgress("ReachPlace", Area.Name)
                            ReachPlace = true

                            Connection:Disconnect()
                        elseif Event:HasGoal("AllReachPlace") then
                            ReachPlace = true
                            Event:UpdateProgress("ReachPlace", Area.Name)
                        end
                    end

                    if not ReachPlace then
                        self:BeginEvent(Area.Name,{PlayersLibrary:GetFromAgent(Agent) :: Types.StagePlayer})
                    end
                end)
            end)

            table.insert(self.__Current_Active_Triggers, Connection);
        end
    end
end

function MissionClass.CleanUpTriggers(self: Types.MissionClass): ()
    for _, TriggerConnection: RBXScriptConnection in self.__Current_Active_Triggers do
        TriggerConnection:Disconnect()
    end

    self.__Current_Active_Triggers = {}
end

function MissionClass.Sync(self: Types.MissionClass, Players: {Types.StagePlayer}, Type: number, ...): ()
    -- Should send to all clients the info about new event
    --[[for _, Player in Players do
        Network:Fire("Match", Player:GetBase(), Type, ...)
    end]]

    warn("This event dont rly do nun")
end

--

return MissionClass