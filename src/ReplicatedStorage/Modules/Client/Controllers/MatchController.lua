--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

--
local EventStates = require(Client.States.Events)
local InterfaceController = require(script.Parent.InterfaceController)

local Controller = {}

function Controller:Init()
    Network:On("Match", function(Type: number, ...)
        print(Type, ...)

        if Type == GameEnum.MatchEvents.BeginEvent then
            Controller:BeginEvent(...)
        elseif Type == GameEnum.MatchEvents.EndEvent then
            Controller:EndEvent(...)
        elseif Type == GameEnum.MatchEvents.SetupStage then
            Controller:SetupStage(...)
        elseif Type == GameEnum.MatchEvents.ProgressUpd then
            Controller:UpdateProgress(...)
        end
    end)
end

function Controller:SetupStage(StageName: string, ActName: string)
    local Component = InterfaceController:GetComponent("Objective")

    Component:SetStage(StageName, ActName)
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