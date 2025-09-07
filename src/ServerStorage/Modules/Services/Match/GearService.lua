--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local AgentTypes = require(Shared.Types.Agents)
local GearDatabase = require(Database.Gears)
local Network = require(Shared.Network)
local Signal = require(Shared.Utility.Signal)

--
local Service = {
    __Queue = {},
    __Prompt_Objects = {},
}

local function ValidateAndPrompt(Player: Player, List: {string}): boolean
    local Result = false

    local CorrectedList = {}
    for _, Name in List do
        if GearDatabase:GetGearData(Name) then
            Result = true

            if table.find(CorrectedList, Name) then
                continue
            end

            table.insert(CorrectedList, Name)
        end
    end

    --
    Network:Fire("Gear", Player, GameEnum.GearEvent.Prompt, CorrectedList)

    return Result, CorrectedList
end

local function CreateObject(Agent: AgentTypes.ServerAgentClass, List: {})
    local Player = Agent.__Player_Assigned
    local Object = {
        Agent = Agent,
        Gear = List,

        Event = Signal.new() :: Signal.ScriptSignal<string | {string}>,

    }

    Service.__Prompt_Objects[Player] = Object

    return Object
end

local function GiveGear(Player: Player, Data: {})
    local Object = Service.__Prompt_Objects[Player]

    if Object then
        Object.Event:Fire(Data[1])
    end
end

function Service:Init()
    --
    Network.new("Gear", "Event")
    Network:On('Gear', function(Player: Player, Type: number, Data: {string})
        if Type == GameEnum.GearEvent.Choose then
            GiveGear(Player, Data)
        end
    end)
end

function Service:PromptOptions(Agent: AgentTypes.ServerAgentClass, List: {})
    local Player = Agent.__Player_Assigned :: Player

    if Service.__Prompt_Objects[Player] then
        if not Service.__Queue[Player] then
            Service.__Queue[Player] = {}
        end

        table.insert(Service.__Queue[Player], List)

        return
    end

    local Success, CorrectedList = ValidateAndPrompt(Player, List)
    if not Success then
        warn("Failed to prompt gear options for player: ", Player)

        return
    end

    local Object = CreateObject(Agent, CorrectedList)
    local Choice = Object.Event:Wait()

    local GearManager = Agent:GetGearManager()

    if typeof(Choice) == 'string' then
        GearManager:AddGear(Choice)
    end

    Service.__Prompt_Objects[Player] = nil

    --
    if Service.__Queue[Player] and #Service.__Queue[Player] > 0 then
        local Initial = table.remove(Service.__Queue[Player], 1)

        Service:PromptOptions(Agent, Initial)
    end
end

return Service