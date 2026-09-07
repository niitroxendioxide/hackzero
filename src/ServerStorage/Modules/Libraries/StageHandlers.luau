--[[
    @class StageHandlers

    Index of the server components that hook a run. Two families, both `StageClass`:

    - `Components/Maps/<Stage>/<Act>`  keyed by stage + act, for a hand-built map
    - `Components/Missions/<Kind>`     keyed by mission kind, for a mission with no map of
                                       its own, e.g. a procedurally generated 'Recover'

    MatchService asks for the mission-kind handler first and falls back to the stage/act
    one, so a runtime-authored mission does not need a stage act to hook into.
]]

local ServerStorage = game:GetService("ServerStorage")

local Components = ServerStorage.Modules.Components
local Handlers = {
    __Stages = {},
    __Missions = {},
    __Ready = false,
}

--[[
    Only modules that are actually a StageClass are kept. A component returning a plain
    table would otherwise be handed to a mission, which then calls ExecuteHooks/SetSeed on
    it and errors mid-run.
]]
local function IsStageClass(Handler: any): boolean
    return typeof(Handler) == 'table' and typeof(Handler.ExecuteHooks) == 'function'
end

local function LoadHandler(Module: Instance, Label: string): any?
    if not Module:IsA('ModuleScript') then
        return nil
    end

    local Valid, Handler = pcall(require, Module)
    if not Valid then
        warn('Invalid handler for ' .. Label .. ': ' .. tostring(Handler))

        return nil
    end

    if not IsStageClass(Handler) then
        warn('Handler for ' .. Label .. ' is not a StageClass, skipping')

        return nil
    end

    return Handler
end

function Handlers:Init()
    --[[
        Framework spawns every service's Init in parallel, so a caller can reach this index
        before it has been filled. Building on demand keeps that from silently resolving to
        no handler, and makes Framework's own call a no-op when it lands second.
    ]]
    if Handlers.__Ready then
        return
    end

    Handlers.__Ready = true

    local Maps = Components:FindFirstChild('Maps')
    local Missions = Components:FindFirstChild('Missions')

    for _, Stage in (Maps and Maps:GetChildren() or {}) do
        local StageName = Stage.Name
        Handlers.__Stages[StageName] = {}

        for _, Act in Stage:GetChildren() do
            local Handler = LoadHandler(Act, 'stage: ' .. StageName .. ' act: ' .. Act.Name)

            if Handler then
                Handlers.__Stages[StageName][Act.Name] = Handler
            end
        end
    end

    for _, Mission in (Missions and Missions:GetChildren() or {}) do
        local Handler = LoadHandler(Mission, 'mission kind: ' .. Mission.Name)

        if Handler then
            Handlers.__Missions[Mission.Name] = Handler
        end
    end
end

--- Component for a stage's act, nil when that act has none.
function Handlers:Get(Stage: string, Act: string)
    Handlers:Init()

    if Stage == nil or Act == nil or Handlers.__Stages[Stage] == nil then
        return nil
    end

    return Handlers.__Stages[Stage][Act]
end

--[[
    Component for a mission kind, nil when that kind has none.
    This is what a runtime-authored mission hooks into, since it has no act of its own.
]]
function Handlers:GetMission(Kind: string?)
    Handlers:Init()

    if Kind == nil then
        return nil
    end

    return Handlers.__Missions[Kind]
end

--[[
    The component that should run this mission: its kind's handler when there is one,
    otherwise the stage act's.
]]
function Handlers:Resolve(Kind: string?, Stage: string?, Act: string?)
    return Handlers:GetMission(Kind) or Handlers:Get(Stage, Act)
end

--- Every registered mission kind, for validating a packet before it is sent.
function Handlers:GetMissionKinds(): {string}
    Handlers:Init()

    local Kinds = {}

    for Kind in Handlers.__Missions do
        table.insert(Kinds, Kind)
    end

    return Kinds
end

return Handlers
