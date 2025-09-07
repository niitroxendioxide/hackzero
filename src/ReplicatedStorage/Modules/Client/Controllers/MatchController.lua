--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local LocalData = require(Client.Libraries.LocalData)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local EventStates = require(Client.States.Events)
local Cutscenes = require(Client.Libraries.Cutscenes)
local InterfaceController = require(script.Parent.InterfaceController)
local CombatController = require(script.Parent.CombatController)
local Camera = require(Client.Libraries.Camera)

local Controller = {}

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
            Controller:BeginMatch(...)
        end
    end)

    Network:On("Gear", function(Type: number, List: {})
        if Type == GameEnum.GearEvent.Prompt then
            Controller:PromptGearChoice(List)
        end
    end)
end

function Controller:PromptGearChoice(List: {string})
    local Component = InterfaceController:GetComponent("Gear")

    Component:ShowOptions(List)
end

function Controller:SetupStage(StageName: string, ActName: string)
    local Component = InterfaceController:GetComponent("Objective")

    LocalData:SetStageData(StageName, ActName)
    Component:SetStage(StageName, ActName)
end

function Controller:BeginMatch(Payload: {})
    Cutscenes:Start("Entrance")
    Cutscenes:WaitCurrent()

    Camera:RotateTo(CombatController:GetCurrentCharacter():GetPivot() * CFrame.new(0, 1, 2))

    CombatController:SetCombatState(true)

    Network:Fire('Match', GameEnum.MatchEvents.MarkClientLoaded)
end

function Controller:MatchEnded(ServerData: {})
    local Component = InterfaceController:GetComponent("EndScreen")
    local Objective = InterfaceController:GetComponent("Objective")

    Component:ShowData(ServerData)
    Component:Set(true)
    Objective:Set(false)
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