--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Player = Players.LocalPlayer

local Characters = require(ReplicatedStorage.Modules.Client.Libraries.Characters)
local World = require(ReplicatedStorage.Modules.Shared.World)
local LocalData = require(Client.Libraries.LocalData)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local EventStates = require(Client.States.Events)
local Cutscenes = require(Client.Libraries.Cutscenes)
local InterfaceController = require(script.Parent.InterfaceController)
local CombatController = require(script.Parent.CombatController)
local Camera = require(Client.Libraries.Camera)

local Controller = {
    __Began = false :: boolean,
    __Total_Waves = 0 :: number,
}

function Controller:HasBegun(): boolean
    return Controller.__Began
end

function Controller:Init()
    Network:On("Match", function(Type: number, ...)
        if Type == GameEnum.MatchEvents.BeginEvent then
            Controller:BeginEvent(...)
        elseif Type == GameEnum.MatchEvents.EndEvent then
            Controller:EndEvent(...)
        elseif Type == GameEnum.MatchEvents.SetupStage then
            Controller:SetupStage(...)
        elseif Type == GameEnum.MatchEvents.ProgressUpd then
            Controller:UpdateProgress(...)
        elseif Type == GameEnum.MatchEvents.MatchEnded then
            Controller:MatchEnded(...)
        elseif Type == GameEnum.MatchEvents.MatchBegin then
            Controller.__Began = true
            Controller:BeginMatch(...)
        elseif Type == GameEnum.MatchEvents.UpdateWave then
            Controller:UpdateCurrentWave(...)
        end
    end)

    Network:On("Gear", function(Type: number, List: {})
        if Type == GameEnum.GearEvent.Prompt then
            Controller:PromptGearChoice(List)
        elseif Type == GameEnum.GearEvent.Give then
            local AgentId = List[1]
            local GearName = List[2]
            local RepId = Player:GetAttribute("ReplicationId") :: number

            local Agent = Characters:GetAgent(RepId, AgentId)

            Agent.__Gear:AddGear(GearName)
        end
    end)
end



-- // Client
function Controller:PromptGearChoice(List: {string})
    local Component = InterfaceController:GetComponent("Gear")

    local Signal = Component:ShowOptions(List)
    local ChosenName: string, _: number = Signal:Wait()

    Network:Fire("Gear", GameEnum.GearEvent.Choose, {ChosenName})
end

function Controller:SetupStage(StageName: string, ActName: string)
    local Component = InterfaceController:GetComponent("Objective")

    LocalData:SetStageData(StageName, ActName)
    Component:SetStage(StageName, ActName)
end

function Controller:BeginMatch(Payload: {})
    Cutscenes:Start("Entrance")
    Cutscenes:WaitCurrent()

    --
    local Objective = InterfaceController:GetComponent("Objective")
    if Payload.TotalWaves then
        Objective:SetMode('Waves')
        Controller.__Total_Waves = Payload.TotalWaves
        Controller:UpdateCurrentWave(1)
    end

    Camera:RotateTo(CombatController:GetCurrentCharacter():GetPivot() * CFrame.new(0, 1, 2))

    CombatController:SetCombatState(true)

    Network:Fire('Match', GameEnum.MatchEvents.MarkClientLoaded)
end

function Controller:MatchEnded(ServerData: {})
    local Component = InterfaceController:GetComponent("EndScreen")
    local Objective = InterfaceController:GetComponent("Objective")

    World:SetSpeed(0.01)

    Component:ShowData(ServerData)
    Component:Set(true)
    Objective:Set(false)
end

function Controller:UpdateCurrentWave(WaveId: number)
    local Objective = InterfaceController:GetComponent("Objective")

    Objective:SetWave(WaveId, Controller.__Total_Waves)
end

function Controller:UpdateProgress(Ev: string, Key: string, Value: any)
    EventStates:Set(Ev, Key, Value)
end

function Controller:BeginEvent(Event: string)
    local Component = InterfaceController:GetComponent("Objective")

    Component:CreateEvent(Event)
end

function Controller:EndEvent(Event: string)
    local Component = InterfaceController:GetComponent("Objective")

    Component:DeleteEvent(Event)
end

return Controller