--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)

--
local Stages = {
    __Cache = {},
}

function Stages:Init()

    for _, Module in script:GetChildren() do
        local Success, Data = pcall(require, Module)

        if Success then
            Stages.__Cache[Module.Name] = table.freeze(Data)
        else
            warn("Error on stage data for [", Module.Name, "]:", Data)
        end
    end
end

function Stages:GetStage(StageName: string): Types.Stage
    return Stages.__Cache[StageName]
end

function Stages:GetAct(StageName: string, Act: string): Types.Stage_Act
    local Stage = Stages:GetStage(StageName)

    return Stage.Acts[Act]
end

function Stages:GetEvent(StageName: string, ActName: string, Event: string)
    local Act = Stages:GetAct(StageName, ActName)

    return Act.Guide[Event]
end

return Stages