--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Stages)

--
local Stages = {
    __Cache = {},
    __Cached_Ordered_Acts = {},
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

local function OrderActsForStage(Stage: string)
    Stages.__Cached_Ordered_Acts[Stage] = {}

    for ActName in Stages:GetStage(Stage).Acts do
        table.insert(Stages.__Cached_Ordered_Acts[Stage], ActName)
    end

    table.sort(Stages.__Cached_Ordered_Acts[Stage], function(a, b) return a > b end)
end

function Stages:GetStage(StageName: string): Types.Stage
    return Stages.__Cache[StageName]
end

function Stages:GetAct(StageName: string, Act: string): Types.Stage_Act
    local Stage = Stages:GetStage(StageName)
    if not Stage then
        return nil
    end

    return Stage.Acts[Act]
end

function Stages:GetAll()
    return Stages.__Cache
end

function Stages:GetAllActs(Stage: string): { [string]: Types.Stage_Act }
    return Stages.__Cache[Stage].Acts
end


function Stages:GetEvent(StageName: string, ActName: string, Event: string)
    local Act = Stages:GetAct(StageName, ActName)
    if not Act then
        return
    end

    return Act.Guide[Event]
end

function Stages:GetOrderedActId(Stage: string, Act: string): number?
    if not Stages.__Cached_Ordered_Acts[Stage] then
        OrderActsForStage(Stage)
    end

    return table.find(Stages.__Cached_Ordered_Acts[Stage], Act)
end

function Stages:GetActById(Stage: string, Act: number): string
    if not Stages.__Cached_Ordered_Acts[Stage] then
        OrderActsForStage(Stage)
    end

    return Stages.__Cached_Ordered_Acts[Stage][Act]
end

return Stages